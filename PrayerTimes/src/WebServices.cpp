#include "WebServices.hpp"
#include <bb/data/JsonDataAccess>
#include <QtNetwork/QNetworkRequest>
#include <QtNetwork/QSslConfiguration>
#include <QtNetwork/QSslSocket>
#include <QUrl>
#include <QFile>
#include <QDir>
#include <QDate>
#include <bb/platform/Notification>
#include <bb/system/InvokeRequest>
#include <QDateTime>
#include <QtConcurrentRun>

#include <bb/pim/calendar/CalendarService>
#include <bb/pim/calendar/CalendarEvent>
#include <bb/pim/calendar/CalendarFolder.hpp>

#include <QtAlgorithms>
#include <bb/pim/calendar/EventSearchParameters>

using namespace bb::platform;
using namespace bb::cascades;
using namespace bb::data;
using namespace bb::pim::calendar;

static bool compareCountriesFunc(const QVariant &v1, const QVariant &v2) {
    QVariantMap m1 = v1.toMap();
    QVariantMap m2 = v2.toMap();

    QString id1 = m1["_id"].toString();
    QString id2 = m2["_id"].toString();

    QString nameEn1 = m1["name_en"].toString().trimmed();
    QString nameEn2 = m2["name_en"].toString().trimmed();

    QString nameTr1 = m1["name"].toString().trimmed();
    QString nameTr2 = m2["name"].toString().trimmed();

    // Türkiye Kontrolü
    bool isTurkey1 = (id1 == "2");
    bool isTurkey2 = (id2 == "2");

    if (isTurkey1 && !isTurkey2) return true;  // Türkiye öne geçer
    if (!isTurkey1 && isTurkey2) return false; // Diğeri arkada kalır

    // A-Z Sıralaması
    return nameEn1.localeAwareCompare(nameEn2) < 0;
}

WebServices::WebServices(QObject *parent) : QObject(parent), m_isManualSaving(false) {
    m_networkManager = new QNetworkAccessManager(this);
    m_countryModel = new ArrayDataModel(this);
    m_cityModel = new ArrayDataModel(this);
    m_districtModel = new ArrayDataModel(this);

    // Yeni API endpoint yapısı
    m_serverUrl = "https://berrybeeper.duckdns.org/prayertimes";

    m_timer = new QTimer(this);
    // Vakit geri sayım
    connect(m_timer, SIGNAL(timeout()), this, SLOT(updateCountdown()));
    m_timer->start(60000);

    if (!m_invokeManager) {
            m_invokeManager = new bb::system::InvokeManager(this);
        }

    // --- GLOBAL SSL/TLS KONFİGÜRASYONU ---
    QSslConfiguration sslConfig = QSslConfiguration::defaultConfiguration();
    sslConfig.setProtocol(QSsl::SecureProtocols);
    sslConfig.setPeerVerifyMode(QSslSocket::VerifyNone);
    QSslConfiguration::setDefaultConfiguration(sslConfig);
    // QNetworkAccessManager üzerindeki tüm HTTPS SSL hatalarını otomatik yok say
    connect(m_networkManager, SIGNAL(sslErrors(QNetworkReply*, QList<QSslError>)),
            this, SLOT(onGlobalSslErrors(QNetworkReply*, QList<QSslError>)));
}

// REST Isteklerinde olusan SSL hatalarini otomatik bastiran slot
void WebServices::onGlobalSslErrors(QNetworkReply *reply, const QList<QSslError> &errors) {
    Q_UNUSED(errors);
    if (reply) {
        reply->ignoreSslErrors();
    }
}

// Donma kontrolü için property metodları
bool WebServices::isBusy() const { return m_isBusy; }
void WebServices::setBusy(bool busy) {
    if (m_isBusy != busy) {
        m_isBusy = busy;
        emit isBusyChanged();
    }
}

// --- LOKAL DOSYA YOLU ---
QString getMonthlyFilePath() {
    return QDir::currentPath() + "/data/monthly_times.json";
}

// --- ÜLKELER, ŞEHİRLER, İLÇELER (Aynı kalıyor) ---
void WebServices::fetchCountries() {
    m_countryModel->clear();
    QNetworkRequest request(QUrl(m_serverUrl + "/countries"));
    request.setRawHeader("Accept", "application/json");
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, SIGNAL(finished()), this, SLOT(onCountriesReply()));
}


void WebServices::onCountriesReply() {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();

        if (responseData.startsWith("\xEF\xBB\xBF")) {
            responseData.remove(0, 3);
        }
        responseData = responseData.trimmed();

        JsonDataAccess jda;
        QVariant rawJson = jda.loadFromBuffer(responseData);

        if (!jda.hasError() && rawJson.type() == QVariant::Map) {
            QVariantMap res = rawJson.toMap();

            if (res.contains("data")) {
                m_countryModel->clear();

                QVariantList list = res["data"].toList();

                // C++98 uyumlu static fonksiyon adresi ile qSort
                qSort(list.begin(), list.end(), compareCountriesFunc);

                for (int i = 0; i < list.size(); ++i) {
                    m_countryModel->append(list.at(i).toMap());
                }

                qDebug() << "::: Ulkeler Sıralandi (Turkiye en basta). Toplam:" << m_countryModel->size();

                emit countryModelChanged();
            }
        } else {
            qDebug() << "::: JSON Parse Hatasi:" << jda.error().errorMessage();
        }

    } else {
        qDebug() << "::: Network Hatasi:" << reply->errorString();
    }

    reply->deleteLater();
}
void WebServices::fetchCities(const QString &countryId) {
    m_cityModel->clear();
    m_districtModel->clear();
    QNetworkRequest request(QUrl(m_serverUrl + "/states/" + countryId));
    request.setRawHeader("Accept", "application/json");
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, SIGNAL(finished()), this, SLOT(onCitiesReply()));
}

void WebServices::onCitiesReply() {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();

        // BOM ve boşluk temizliği
        if (responseData.startsWith("\xEF\xBB\xBF")) {
            responseData.remove(0, 3);
        }
        responseData = responseData.trimmed();

        JsonDataAccess jda;
        QVariant rawJson = jda.loadFromBuffer(responseData);

        if (!jda.hasError() && rawJson.type() == QVariant::Map) {
            QVariantMap res = rawJson.toMap();

            if (res.contains("data")) {
                m_cityModel->clear();

                QVariantList list = res["data"].toList();

                for (int i = 0; i < list.size(); ++i) {
                    m_cityModel->append(list.at(i).toMap());
                }

                qDebug() << "::: Sehirler Yuklendi. Toplam Sehir Sayisi:" << m_cityModel->size();

                emit cityModelChanged();
            } else {
                qDebug() << "::: Sehirler JSON 'data' alani bulunamadi!";
            }
        } else {
            qDebug() << "::: Sehirler JSON Parse Hatasi:" << jda.error().errorMessage();
        }

    } else {
        qDebug() << "::: Sehirler Network Hatasi:" << reply->errorString();
    }

    reply->deleteLater();
}

void WebServices::fetchDistricts(const QString &cityId) {
    m_districtModel->clear();
    QNetworkRequest request(QUrl(m_serverUrl + "/districts/" + cityId));
    request.setRawHeader("Accept", "application/json");
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, SIGNAL(finished()), this, SLOT(onDistrictsReply()));
}

void WebServices::onDistrictsReply() {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (reply->error() == QNetworkReply::NoError) {
        JsonDataAccess jda;
        QVariantMap res = jda.loadFromBuffer(reply->readAll()).toMap();
        m_districtModel->clear();
        m_districtModel->append(res["data"].toList());
        emit districtModelChanged();
    }
    reply->deleteLater();
}

void WebServices::fetchPrayerTimes() {
    QSettings settings;
    QString id = settings.value("selected_district_id").toString();
    if (id.isEmpty()) return;

    QString bugun = QDate::currentDate().toString("yyyy-MM-dd");

    QFile file(getMonthlyFilePath());
    if (file.exists() && file.open(QIODevice::ReadOnly)) {
        JsonDataAccess jda;
        QVariantMap wrapper = jda.loadFromBuffer(file.readAll()).toMap();
        QVariantList yearlyData = wrapper["monthly_data"].toList();
        file.close();

        qDebug() << "DEBUG: Cevrimdisi dosya okundu. Kayit sayisi:" << yearlyData.size();

        foreach (const QVariant &gun, yearlyData) {
            QVariantMap gunMap = gun.toMap();
            // BURASI KRİTİK: Dosyadaki tarihin de sadece ilk 10 karakterine bakıyoruz
            QString temizTarih = gunMap["date"].toString().left(10);

            if (temizTarih == bugun) {
                m_prayerTimes = gunMap["times"].toMap();
                m_prayerTimes["date"] = temizTarih;
                m_prayerTimes["hijri_date"] = gunMap["hijri_date"];

                qDebug() << "DEBUG: Çevrimdışı veri başarıyla yüklendi:" << temizTarih;

                emit prayerTimesChanged();
                updateCountdown();
                resetService();
                return; // Bugün bulundu, fonksiyonu bitir
            }
        }
        qDebug() << "DEBUG: Dosyada bugünün tarihi bulunamadı, API'ye gidiliyor...";
    }

    // Dosya yoksa veya bugün bulunamadıysa API'ye git
    fetchPrayerTimesById(id);
}

void WebServices::fetchPrayerTimesById(QString districtId) {
    if (districtId.isEmpty()) return;
    // URL'yi /yearly olarak güncelliyoruz
    QUrl url(m_serverUrl + "/times/" + districtId + "/monthly");
    QNetworkRequest request(url);
    request.setRawHeader("Accept", "application/json");
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, SIGNAL(finished()), this, SLOT(onPrayerTimesReply()));
}

void WebServices::onPrayerTimesReply() {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        JsonDataAccess jda;

        // 1. Gelen ham veriyi Map olarak oku
        QVariantMap root = jda.loadFromBuffer(responseData).toMap();

        // DEBUG: Gelen veride 'data' var mı kontrol et
        qDebug() << "DEBUG: Root anahtarlari:" << root.keys();

        // Sunucu 'data' anahtarı içinde bir liste gönderiyor olmalı
        QVariantList dataList = root["data"].toList();
        qDebug() << "DEBUG: Liste uzunlugu:" << dataList.size();

        if (!dataList.isEmpty()) {
            // YILLIK VERİYİ KAYDET (Zaten çalışıyor demiştin)
            QVariantMap wrapper;
            wrapper["monthly_data"] = dataList;
            QFile file(getMonthlyFilePath());
            if (file.open(QIODevice::WriteOnly)) {
                jda.save(wrapper, &file);
                file.close();
                qDebug() << "DEBUG: Yillik veri kaydedildi.";
            }

            // SADECE manuel kayıt işlemi dışındaysak takvimi planla
            if (!m_isManualSaving) {
                scheduleBatchNotifications(dataList);
            }

            m_isManualSaving = false; // Her durumda kilidi aç

            // 2. BUGÜNÜN VERİSİNİ AYIKLA
            QString bugun = QDate::currentDate().toString("yyyy-MM-dd");
            bool bulundu = false;

            foreach (const QVariant &gun, dataList) {
                QVariantMap gunMap = gun.toMap();
                // "2026-03-25T00:00:00.000Z" -> sol taraftan ilk 10 karakteri al: "2026-03-25"
                QString tamTarih = gunMap["date"].toString();
                QString temizTarih = tamTarih.left(10);

                if (temizTarih == bugun) {
                    m_prayerTimes = gunMap["times"].toMap();
                    m_prayerTimes["date"] = temizTarih;
                    m_prayerTimes["hijri_date"] = gunMap["hijri_date"];

                    qDebug() << "DEBUG: Bugun ESLESTI!" << temizTarih;

                    // ÖNCE veriyi set edip SONRA sinyalleri gönderiyoruz
                    emit prayerTimesChanged();
                    updateCountdown(); // Bu fonksiyon zaten emit remainingTimeChanged() ve currentVakitChanged() yapıyor
                    resetService();

                    bulundu = true;
                    break;
                }
            }

            if (!bulundu) {
                qDebug() << "HATA: Liste icinde bugunun tarihi bulunamadi!";
            }

        } else {
            qDebug() << "HATA: 'data' listesi bos geldi!";
        }
    } else {
        qDebug() << "Network Hatasi:" << reply->errorString();
    }
    reply->deleteLater();
}

bool WebServices::hasSavedLocation() {
    QSettings settings;
    return settings.contains("selected_district_id");
}

void WebServices::updateCountdown() {
    if (m_prayerTimes.isEmpty() || !m_prayerTimes.contains("imsak")) return;

    QTime simdi = QTime::currentTime();

    // 1. Anahtarları basit tutalım (Küçük harf, Türkçe karaktersiz)
    QMap<QString, QTime> vakitler;
    vakitler["imsak"]  = QTime::fromString(m_prayerTimes["imsak"].toString(), "HH:mm");
    vakitler["gunes"]  = QTime::fromString(m_prayerTimes["gunes"].toString(), "HH:mm");
    vakitler["ogle"]   = QTime::fromString(m_prayerTimes["ogle"].toString(), "HH:mm");
    vakitler["ikindi"] = QTime::fromString(m_prayerTimes["ikindi"].toString(), "HH:mm");
    vakitler["aksam"]  = QTime::fromString(m_prayerTimes["aksam"].toString(), "HH:mm");
    vakitler["yatsi"]  = QTime::fromString(m_prayerTimes["yatsi"].toString(), "HH:mm");

    // 2. Bu liste Map'teki anahtarlarla BİREBİR aynı olmalı
    QStringList anahtarlar;
    anahtarlar << "imsak" << "gunes" << "ogle" << "ikindi" << "aksam" << "yatsi";

    // 3. QML'e gidecek şık isimler için ayrı bir liste
    QStringList gorunurIsimler;
    gorunurIsimler << QString::fromUtf8("İmsak") << QString::fromUtf8("Güneş")
                   << QString::fromUtf8("Öğle") << QString::fromUtf8("İkindi")
                   << QString::fromUtf8("Akşam") << QString::fromUtf8("Yatsı");

    QString hedefVakitIsmi = gorunurIsimler[0]; // Varsayılan İmsak
    QTime hedefVakit = vakitler["imsak"];
    m_currentVakit = gorunurIsimler[5]; // Varsayılan Yatsı (Gece yarısı durumu)

    bool bulundu = false;
    for (int i = 0; i < anahtarlar.size(); ++i) {
        if (simdi < vakitler[anahtarlar[i]]) {
            hedefVakitIsmi = gorunurIsimler[i];
            hedefVakit = vakitler[anahtarlar[i]];
            // Eğer İmsak'tan önceysek bir önceki vakit Yatsı'dır
            m_currentVakit = (i == 0) ? gorunurIsimler[5] : gorunurIsimler[i-1];
            bulundu = true;
            break;
        }
    }

    // Eğer döngü bittiyse ve bulunamadıysa vakit Yatsı'dan sonradır, hedef yarınki İmsak'tır
    if (!bulundu) {
        m_currentVakit = gorunurIsimler[5]; // Yatsı
        hedefVakit = vakitler["imsak"];
    }

    // 4. Saniye farkını al ve negatifse 24 saat ekle (Yatsı sonrası durumu)
    int saniye = simdi.secsTo(hedefVakit);
    if (saniye < 0) saniye += 86400;

    int saat = saniye / 3600;
    int dakika = (saniye % 3600) / 60;

    m_remainingTime = QString("%1:%2")
                        .arg(saat, 2, 10, QChar('0'))
                        .arg(dakika, 2, 10, QChar('0'));

    emit remainingTimeChanged();
    emit currentVakitChanged();
}


// Okuma fonksiyonu (S takısını buraya da ekleyin)
bool WebServices::getNotificationSetting(const QString &vakit, bool defaultValue) {
    return m_settings.value("notifications/" + vakit, defaultValue).toBool(); // 'notifications'
}


QString WebServices::getSavedValue(const QString &key) {
    // QSettings içinden anahtarı oku, yoksa boş dön
    return m_settings.value(key, "").toString();
}

void WebServices::scheduleBatchNotifications(const QVariantList &dataList) {
    bb::pim::calendar::CalendarService calendarService;
    QDateTime suan = QDateTime::currentDateTime();
    QDate bugun = suan.date();
    QDate onGunSonra = bugun.addDays(1);

    QList<bb::pim::calendar::CalendarFolder> folders = calendarService.folders();
    if (folders.isEmpty()) return;

    bb::pim::calendar::CalendarFolder targetFolder = folders.first();
    foreach (const bb::pim::calendar::CalendarFolder &f, folders) {
        if (!f.isReadOnly()) { targetFolder = f; break; }
    }

    foreach (const QVariant &gun, dataList) {
        QVariantMap gunMap = gun.toMap();
        QString dateStr = gunMap["date"].toString().left(10);
        QDate hedefTarih = QDate::fromString(dateStr, "yyyy-MM-dd");

        if (!hedefTarih.isValid() || hedefTarih < bugun || hedefTarih > onGunSonra) continue;

        QVariantMap timesMap = gunMap["times"].toMap();
        QStringList vakitler;
        vakitler << "imsak" << "gunes" << "ogle" << "ikindi" << "aksam" << "yatsi";

        foreach (const QString &vakit, vakitler) {
            bool ayarDurumu = getNotificationSetting(vakit, false);
            if (!ayarDurumu) continue;

            QString vVakti = timesMap[vakit].toString();
            QTime vakitSaati = QTime::fromString(vVakti, "HH:mm");
            QDateTime eventStart(hedefTarih, vakitSaati);

            if (!vakitSaati.isValid()) continue;
            if (eventStart < suan) continue;

            bb::pim::calendar::CalendarEvent ev;
            ev.setSubject(vakit.toUpper() + " Vakti");
            ev.setStartTime(eventStart);

            // Sizin kodunuzdaki yapı (durations kullanımı)
            int userDurationMinutes = m_settings.value("durations/" + vakit, 15).toInt();
            ev.setEndTime(eventStart.addSecs(userDurationMinutes*60));

            ev.setBody("PrayerAppEvent");
            ev.setAccountId(targetFolder.accountId());
            ev.setFolderId(targetFolder.id());
            ev.setBusyStatus(bb::pim::calendar::BusyStatus::Busy);

            int userReminderMinutes = m_settings.value("reminders/" + vakit, 15).toInt();
            ev.setReminder(userReminderMinutes);

            calendarService.createEvent(ev);
        }
    }
}


void WebServices::clearFutureCalendarEvents(const QString &vakitAdi) {
    bb::pim::calendar::CalendarService calendarService;

    // Madem setStart ve setEnd hata vermedi, en yalın hallerini kullanıyoruz:
    bb::pim::calendar::EventSearchParameters params;
    params.setStart(QDateTime::currentDateTime());
    params.setEnd(QDateTime::currentDateTime().addDays(10));

    // Etkinlikleri çek
    QList<bb::pim::calendar::CalendarEvent> events = calendarService.events(params);

    QString searchKey = vakitAdi.toUpper();

    foreach (const bb::pim::calendar::CalendarEvent &ev, events) {
        if (ev.body() == "PrayerAppEvent") {
            if (searchKey.isEmpty() || ev.subject().contains(searchKey)) {

                // Hata veren satırı şununla değiştirin:
                calendarService.deleteEvent(ev);

                // EĞER yukarıdaki çalışmazsa (SDK sürümüne göre), şunu deneyin:
                // calendarService.deleteEvent(ev.accountId(), ev.id());
            }
        }
    }

    qDebug() << ">>> TEMIZLIK TAMAMLANDI: " << (vakitAdi.isEmpty() ? "HEPSI" : vakitAdi);
}

void WebServices::loadMonthlyDataAndSchedule() {
    QFile file(getMonthlyFilePath());
    if (file.open(QIODevice::ReadOnly)) {
        JsonDataAccess jda;
        QVariantMap root = jda.load(&file).toMap();
        QVariantList dataList = root["monthly_data"].toList();

        if (!dataList.isEmpty()) {
            clearFutureCalendarEvents("");
            scheduleBatchNotifications(dataList);
        }
    }
}

void WebServices::saveAllSettings(const QVariantMap &settingsMap,
                                  const QVariantMap &reminderMap,
                                  const QVariantMap &durationMap,
                                  const QString &countryId,
                                  const QString &cityId,
                                  const QString &districtId,
                                  const QString &districtName)
{
    m_isManualSaving = true;
    QStringList vakitler;
    vakitler << "imsak" << "gunes" << "ogle" << "ikindi" << "aksam" << "yatsi";

    // 1. Bildirim (ON/OFF) Ayarlarını Kaydet
    foreach (const QString &vakit, vakitler) {
        if (settingsMap.contains(vakit)) {
            bool enabled = settingsMap.value(vakit).toBool();
            m_settings.setValue("notifications/" + vakit, enabled);
        }
    }

    // 2. YENİ: Öncül Bildirim (Dakika) Ayarlarını Kaydet
    foreach (const QString &vakit, vakitler) {
        if (reminderMap.contains(vakit)) {
            // TextField'dan gelen metni sayıya çevirip kaydediyoruz
            int minutes = reminderMap.value(vakit).toInt();
            m_settings.setValue("reminders/" + vakit, minutes);
        }
    }

    // 1. Bildirim (ON/OFF) Ayarlarını Kaydet
    foreach (const QString &vakit, vakitler) {
        if (durationMap.contains(vakit)) {
            // TextField'dan gelen metni sayıya çevirip kaydediyoruz
            int minutes = durationMap.value(vakit).toInt();
            m_settings.setValue("durations/" + vakit, minutes);
        }
    }

    // 3. Konum Bilgilerini Kaydet
    if (m_settings.value("location/district_id").toString() != districtId) {
        QFile::remove(getMonthlyFilePath());
    }
    m_settings.setValue("location/country_id", countryId);
    m_settings.setValue("location/city_id", cityId);
    m_settings.setValue("location/district_id", districtId);
    m_settings.setValue("selected_district_id", districtId);
    m_settings.setValue("selected_district_name", districtName);

    m_settings.sync(); // Disk yazımını zorla
    emit selectedDistrictNameChanged();
    resetService();
    QFile file(getMonthlyFilePath());
    if (file.exists()) {
        loadMonthlyDataAndSchedule();
        m_isManualSaving = false;
    } else {
        fetchPrayerTimesById(districtId);
    }
}

// ASYNC KAYIT VE YÜKLEME (Lambda hatası giderildi)
void WebServices::saveAllSettingsAsync(const QVariantMap &r0, const QVariantMap &r1, const QVariantMap &dur, const QString &cId, const QString &cyId, const QString &dId, const QString &dName) {
    m_tmpR0 = r0; m_tmpR1 = r1; m_tmpDur = dur;
    m_tmpCId = cId; m_tmpCyId = cyId; m_tmpDId = dId; m_tmpDName = dName;

    QTimer::singleShot(600, this, SLOT(onAsyncSaveTriggered()));
}

void WebServices::onAsyncSaveTriggered() {
    this->saveAllSettings(m_tmpR0, m_tmpR1, m_tmpDur, m_tmpCId, m_tmpCyId, m_tmpDId, m_tmpDName);
}

void WebServices::resetService() {
    bb::system::InvokeRequest request;
    request.setTarget("com.example.PrayerTimesService");
    request.setAction("com.example.PrayerTimesService.RESET");
    m_invokeManager->invoke(request);
}


