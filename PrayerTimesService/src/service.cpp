#include "service.hpp"

#include <bb/Application>
#include <bb/platform/Notification>
#include <bb/platform/NotificationDefaultApplicationSettings>
#include <bb/system/InvokeManager>

#include <QtNetwork/QNetworkRequest>
#include <QtNetwork/QSslConfiguration>
#include <QtNetwork/QSslSocket>

#include <bb/pim/calendar/CalendarService>
#include <bb/pim/calendar/CalendarEvent>
#include <bb/pim/calendar/CalendarFolder>
#include <bb/pim/calendar/EventSearchParameters>
#include <bb/data/JsonDataAccess>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QDate>
#include <QDateTime>
#include <QDebug>
#include <QLocale>

using namespace bb::platform;
using namespace bb::system;
using namespace bb::data;
using namespace bb::pim::calendar;

QString getMonthlyFilePath() {
    return QDir::currentPath() + "/data/monthly_times.json";
}

Service::Service() :
        QObject(),
        m_notify(new bb::platform::Notification(this)),
        m_invokeManager(new bb::system::InvokeManager(this)),
        m_prayerTimer(new QTimer(this))
{
    qDebug() << "[PRAYER_SERVICE] Servis constructor basladi.";
    m_serverUrl = "https://berrybeeper.duckdns.org/prayertimes";
    m_networkManager = new QNetworkAccessManager(this);

    m_invokeManager->connect(m_invokeManager, SIGNAL(invoked(const bb::system::InvokeRequest&)),
            this, SLOT(handleInvoke(const bb::system::InvokeRequest&)));

    NotificationDefaultApplicationSettings settings;
    settings.setPreview(NotificationPriorityPolicy::Allow);
    settings.apply();

    m_notify->setTitle("PrayerTimes Service");
    m_notify->setBody("Vakit verileri eksik. Uygulamayı açarak güncelleyin.");

    bb::system::InvokeRequest request;
    request.setTarget("com.example.PrayerTimes");
    request.setAction("bb.action.START");
    m_notify->setInvokeRequest(request);

    // Dynamic Timer Bağlantısı
    connect(m_prayerTimer, SIGNAL(timeout()), this, SLOT(onPrayerTimerFired()));

    // SSL Ayarları
    QSslConfiguration sslConfig = QSslConfiguration::defaultConfiguration();
    sslConfig.setProtocol(QSsl::SecureProtocols);
    sslConfig.setPeerVerifyMode(QSslSocket::VerifyNone);
    QSslConfiguration::setDefaultConfiguration(sslConfig);
    connect(m_networkManager, SIGNAL(sslErrors(QNetworkReply*, QList<QSslError>)),
            this, SLOT(onGlobalSslErrors(QNetworkReply*, QList<QSslError>)));

    qDebug() << "[PRAYER_SERVICE] Servis baslatildi. Ilk hedef vakit hesaplaniyor...";

    // Servis başlar başlamaz ilk hedef vakit hesaplanır ve timer kurulur
    scheduleNextPrayerTimer();
}

void Service::scheduleNextPrayerTimer()
{
    QDateTime now = QDateTime::currentDateTime();
    QDate bugunTarih = now.date();
    QString bugunStr = bugunTarih.toString("yyyy-MM-dd");
    QString yarinStr = bugunTarih.addDays(1).toString("yyyy-MM-dd");

    qDebug() << "[PRAYER_SERVICE] Zamanlayici hesaplaniyor... Su anki zaman:" << now.toString("yyyy-MM-dd HH:mm:ss");

    QString filePath = getMonthlyFilePath();
    QFileInfo checkFile(filePath);

    if (!checkFile.exists() || !checkFile.isReadable()) {
        qDebug() << "[PRAYER_SERVICE] [HATA] Vakit dosyasi bulunamadi! Sunucudan veri isteniyor...";
        fetchPrayerTimes();
        QTimer::singleShot(60000, this, SLOT(scheduleNextPrayerTimer()));
        return;
    }

    JsonDataAccess jda;
    QVariant rawData = jda.load(filePath);
    if (jda.hasError()) {
        qDebug() << "[PRAYER_SERVICE] [HATA] JSON okunamadi! 60 saniye sonra tekrar denenecek.";
        QTimer::singleShot(60000, this, SLOT(scheduleNextPrayerTimer()));
        return;
    }

    QVariantMap root = rawData.toMap();
    QVariantList dataList = root["monthly_data"].toList();

    QVariantMap todaysTimes;
    QVariantMap tomorrowsTimes;

    foreach (const QVariant &gun, dataList) {
        QVariantMap gunMap = gun.toMap();
        QString dateStr = gunMap["date"].toString().left(10);

        if (dateStr == bugunStr) {
            todaysTimes = gunMap["times"].toMap();
        } else if (dateStr == yarinStr) {
            tomorrowsTimes = gunMap["times"].toMap();
        }

        if (!todaysTimes.isEmpty() && !tomorrowsTimes.isEmpty()) {
            break;
        }
    }

    // Bugüne ait veri bulunamadıysa (örneğin ayın 1'i oldu ama henüz yeni ay verisi yok)
    if (todaysTimes.isEmpty()) {
        qDebug() << "[PRAYER_SERVICE] Bugunun vakit verisi yok. Sunucudan cekilmeye calisiliyor...";
        fetchPrayerTimes();
        QTimer::singleShot(60000, this, SLOT(scheduleNextPrayerTimer()));
        return;
    }

    QStringList vakitler;
    vakitler << "imsak" << "gunes" << "ogle" << "ikindi" << "aksam" << "yatsi";

    QString targetVakit = "";
    QDateTime targetDateTime;

    // 1. Bugunun vakitlerini kontrol et (Su andan sonraki ilk vakti bul)
    foreach (const QString &vakit, vakitler) {
        QString vStr = todaysTimes.value(vakit).toString();
        QTime vTime = QTime::fromString(vStr, "HH:mm");
        if (vTime.isValid()) {
            QDateTime vDateTime(bugunTarih, vTime);
            if (vDateTime > now) {
                targetVakit = vakit;
                targetDateTime = vDateTime;
                break;
            }
        }
    }

    // 2. Bugunun tum vakitleri gectiyse (Yatsi sonrası), yarinki IMSAK vakti hedeflenir
    if (targetVakit.isEmpty()) {
        qDebug() << "[PRAYER_SERVICE] Bugunun tüm vakitleri gecti. Yarinki imsak vakti hedefleniyor.";

        if (!tomorrowsTimes.isEmpty()) {
            QString imsakStr = tomorrowsTimes.value("imsak").toString();
            QTime imsakTime = QTime::fromString(imsakStr, "HH:mm");
            if (imsakTime.isValid()) {
                targetVakit = "imsak";
                targetDateTime = QDateTime(bugunTarih.addDays(1), imsakTime);
            }
        } else {
            // YARININ VERISI YOK (AY GEÇİŞİ DURUMU - Örn: 31 Ekim Yatsı sonrası)
            qDebug() << "[PRAYER_SERVICE] [AY GECISI] Yarinki veri bulunamadi. Sunucudan guncel veri isteniyor...";
            fetchPrayerTimes();

            // Gece yarısına (00:00:05) ne kadar kaldığını hesapla
            QDateTime geceYarisi(bugunTarih.addDays(1), QTime(0, 0, 5));
            qint64 msUntilMidnight = now.msecsTo(geceYarisi);

            if (msUntilMidnight > 0 && msUntilMidnight < 86400000) {
                qDebug() << "[PRAYER_SERVICE] Gece yarisi guncellemesi bekleniyor. Kalan ms:" << msUntilMidnight;
                m_prayerTimer->stop();
                m_prayerTimer->setInterval(msUntilMidnight);
                m_prayerTimer->setSingleShot(true);
                m_prayerTimer->start();
                return;
            }
        }
    }

    if (targetVakit.isEmpty() || !targetDateTime.isValid()) {
        qDebug() << "[PRAYER_SERVICE] [HATA] Hedef vakit hesaplanamadi. 60sn sonra tekrar denenecek.";
        QTimer::singleShot(60000, this, SLOT(scheduleNextPrayerTimer()));
        return;
    }

    qint64 msecs = now.msecsTo(targetDateTime);
    if (msecs <= 0) {
        msecs = 1000;
    }

    m_currentScheduledVakit = targetVakit;
    m_tomorrowsTimesForSchedule = tomorrowsTimes;

    qDebug() << "==================================================";
    qDebug() << "[PRAYER_SERVICE] HEDEF VAKIT ZAMANLANDI:";
    qDebug() << "[PRAYER_SERVICE] Vakit:" << targetVakit.toUpper();
    qDebug() << "[PRAYER_SERVICE] Hedef Zaman:" << targetDateTime.toString("yyyy-MM-dd HH:mm:ss");
    qDebug() << "[PRAYER_SERVICE] Kalan Sure:" << (msecs / 1000) << "saniye (" << (msecs / 60000) << "dakika)";
    qDebug() << "==================================================";

    m_prayerTimer->stop();
    m_prayerTimer->setInterval(msecs);
    m_prayerTimer->setSingleShot(true);
    m_prayerTimer->start();
}


void Service::onPrayerTimerFired()
{
    qDebug() << "[PRAYER_SERVICE] *** VAKIT GELDI! TIMER TETIKLENDI *** Vakit:" << m_currentScheduledVakit;
    QSettings settings;

    // Vakit anahtarını küçük harfe ve standart formata getiriyoruz
    QString vakitKey = m_currentScheduledVakit.toLower();

    bool notifyEnabled = settings.value("notifications/" + vakitKey, false).toBool();

    if (notifyEnabled) {
        // Dil ayarını alıyoruz (varsayılan: "en", alternatifler: "tr", "ar")
        QString lang = QLocale::system().name().left(2).toLower();

        QString title;
        QString body;

        if (lang == "tr") {
            title = "Namaz Vakitleri";

            QHash<QString, QString> trVakitler;
            trVakitler["imsak"]  = QString::fromUtf8("İMSAK");
            trVakitler["gunes"]  = QString::fromUtf8("GÜNEŞ");
            trVakitler["ogle"]   = QString::fromUtf8("ÖĞLE");
            trVakitler["ikindi"] = QString::fromUtf8("İKİNDİ");
            trVakitler["aksam"]  = QString::fromUtf8("AKŞAM");
            trVakitler["yatsi"]  = QString::fromUtf8("YATSI");

            QString vakitAdi = trVakitler.value(vakitKey, m_currentScheduledVakit);
            body = QString("%1 Vakti!").arg(vakitAdi);
        }
        else if (lang == "ar") {
            title = QString::fromUtf8("أوقات الصلاة");

            QHash<QString, QString> arVakitler;
            arVakitler["imsak"]  = QString::fromUtf8("الفجر");
            arVakitler["gunes"]  = QString::fromUtf8("الشروق");
            arVakitler["ogle"]   = QString::fromUtf8("الظهر");
            arVakitler["ikindi"] = QString::fromUtf8("العصر");
            arVakitler["aksam"]  = QString::fromUtf8("المغرب");
            arVakitler["yatsi"]  = QString::fromUtf8("العشاء");

            QString vakitAdi = arVakitler.value(vakitKey, m_currentScheduledVakit);
            body = QString::fromUtf8("وقت %1!").arg(vakitAdi);
        }
        else { // Varsayılan: İngilizce ("en")
            title = "Prayer Times";

            QHash<QString, QString> enVakitler;
            enVakitler["imsak"]  = "FAJR";
            enVakitler["gunes"]  = "SUNRISE";
            enVakitler["ogle"]   = "DHUHR";
            enVakitler["ikindi"] = "ASR";
            enVakitler["aksam"]  = "MAGHRIB";
            enVakitler["yatsi"]  = "ISHA";

            QString vakitAdi = enVakitler.value(vakitKey, m_currentScheduledVakit);
            body = QString("%1 Time!").arg(vakitAdi);
        }

        bb::platform::Notification::deleteAllFromInbox();
        // 1. Hub Bildirimi Gönder
        bb::platform::Notification *n = new bb::platform::Notification(this);
        n->setTitle(title);
        n->setBody(body);
        n->notify();
        qDebug() << "[PRAYER_SERVICE] Hub bildirimi gonderildi (" << lang << "):" << title << "-" << body;

        // 2. Takvim İşlemleri
        handleCalendarForVakit(m_currentScheduledVakit, m_tomorrowsTimesForSchedule, QDate::currentDate());
    } else {
        qDebug() << "[PRAYER_SERVICE]" << m_currentScheduledVakit << "icin bildirimler QSettings'te kapali.";
    }

    // İşlem bitti, zaman kaybetmeden BİR SONRAKİ VAKİT için timer kurulur
    scheduleNextPrayerTimer();
}

void Service::handleInvoke(const bb::system::InvokeRequest & request)
{
    if (request.action().compare("com.example.PrayerTimesService.RESET") == 0) {
        qDebug() << "[PRAYER_SERVICE] Invoke alindi:" << request.action();
        scheduleNextPrayerTimer();
    }
}

void Service::clearNotification()
{
    qDebug() << "[PRAYER_SERVICE] triggerNotification tetiklendi.";
    QTimer::singleShot(2000, this, SLOT(onTimeout()));
}

void Service::onTimeout()
{
    qDebug() << "[PRAYER_SERVICE] onTimeout: Bildirim kutusu temizleniyor.";
    bb::platform::Notification::clearEffectsForAll();
}

void Service::onGlobalSslErrors(QNetworkReply *reply, const QList<QSslError> &errors) {
    Q_UNUSED(errors);
    if (reply) {
        reply->ignoreSslErrors();
    }
}

void Service::handleCalendarForVakit(const QString &vakit, const QVariantMap &tomorrowsTimes, const QDate &bugunTarih)
{
    CalendarService calendarService;
    QSettings settings;
    QString subjectToMatch = vakit.toUpper() + " Vakti";

    qDebug() << "[PRAYER_SERVICE] handleCalendarForVakit baslatildi -> Vakit:" << vakit;

    // --- A. ÖNCEKİ GÜNÜN İLGİLİ VAKTİNİ SİL ---
    QDate dun = bugunTarih.addDays(-1);
    EventSearchParameters params;
    params.setStart(QDateTime(dun, QTime(0, 0)));
    params.setEnd(QDateTime(dun, QTime(23, 59)));

    QList<CalendarEvent> events = calendarService.events(params);
    int deletedCount = 0;
    foreach (const CalendarEvent &ev, events) {
        if (ev.body() == "PrayerAppEvent" && ev.subject() == subjectToMatch) {
            calendarService.deleteEvent(ev);
            deletedCount++;
        }
    }
    qDebug() << "[PRAYER_SERVICE] Dunku eski etkinlikler silindi. Adet:" << deletedCount;

    // --- B. YARINKİ GÜN İÇİN İLGİLİ VAKTİ OLUŞTUR ---
    if (tomorrowsTimes.isEmpty()) {
        qDebug() << "[PRAYER_SERVICE] Yarin icin vakit verisi bulunamadi!";
        return;
    }

    QString yarinVakitSaatiStr = tomorrowsTimes.value(vakit).toString();
    if (yarinVakitSaatiStr.isEmpty()) return;

    QTime yarinVakitSaati = QTime::fromString(yarinVakitSaatiStr, "HH:mm");
    if (!yarinVakitSaati.isValid()) return;

    QDate yarin = bugunTarih.addDays(1);
    QDateTime eventStart(yarin, yarinVakitSaati);

    QList<CalendarFolder> folders = calendarService.folders();
    if (folders.isEmpty()) {
        qDebug() << "[PRAYER_SERVICE] HATA: Takvim klasoru bulunamadi!";
        return;
    }

    CalendarFolder targetFolder = folders.first();
    foreach (const CalendarFolder &f, folders) {
        if (!f.isReadOnly()) { targetFolder = f; break; }
    }

    CalendarEvent ev;
    ev.setSubject(subjectToMatch);
    ev.setStartTime(eventStart);

    int userDurationMinutes = settings.value("durations/" + vakit, 15).toInt();
    ev.setEndTime(eventStart.addSecs(userDurationMinutes * 60));

    ev.setBody("PrayerAppEvent");
    ev.setAccountId(targetFolder.accountId());
    ev.setFolderId(targetFolder.id());
    ev.setBusyStatus(bb::pim::calendar::BusyStatus::Busy);

    int userReminderMinutes = settings.value("reminders/" + vakit, 15).toInt();
    ev.setReminder(userReminderMinutes);

    calendarService.createEvent(ev);
    qDebug() << "[PRAYER_SERVICE] Yarin icin takvim etkinligi olusturuldu:" << subjectToMatch << eventStart.toString("yyyy-MM-dd HH:mm");
}

void Service::fetchPrayerTimes() {
    QSettings settings;
    QString districtId = settings.value("selected_district_id").toString();
    if (districtId.isEmpty()) return;

    QUrl url(m_serverUrl + "/times/" + districtId + "/monthly");
    QNetworkRequest request(url);
    request.setRawHeader("Accept", "application/json");
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, SIGNAL(finished()), this, SLOT(onPrayerTimesReply()));
}

void Service::onPrayerTimesReply() {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    const QString ERROR_NOTIF_KEY = "prayer_times_download_error";

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        JsonDataAccess jda;

        QVariantMap root = jda.loadFromBuffer(responseData).toMap();
        QVariantList dataList = root["data"].toList();

        if (!dataList.isEmpty()) {
            QVariantMap wrapper;
            wrapper["monthly_data"] = dataList;
            QFile file(getMonthlyFilePath());
            if (file.open(QIODevice::WriteOnly)) {
                jda.save(wrapper, &file);
                file.close();
                qDebug() << "DEBUG: Aylik veri kaydedildi.";
            }

            // Başarılı indirme yapıldığı için varsa ekrandaki/Hub'daki hata bildirimini kaldır
            bb::platform::Notification::clearEffectsForAll();
            bb::platform::Notification::deleteFromInbox(ERROR_NOTIF_KEY);

            scheduleBatchNotifications(dataList);
            scheduleNextPrayerTimer();
        }
    } else {
        qDebug() << "Network Hatasi:" << reply->errorString();

        // Key constructor'a geçiliyor. Stack nesnesi kullanıldığı için leak oluşmaz.
        bb::platform::Notification n(ERROR_NOTIF_KEY);
        n.setTitle("Prayer Times");
        n.setBody("Failed to download prayer times!");
        n.notify();
    }

    reply->deleteLater();
}

void Service::scheduleBatchNotifications(const QVariantList &dataList) {
    CalendarService calendarService;
    QDateTime suan = QDateTime::currentDateTime();
    QDate bugun = suan.date();
    QDate birGunSonra = bugun.addDays(1);

    QList<CalendarFolder> folders = calendarService.folders();
    if (folders.isEmpty()) return;

    CalendarFolder targetFolder = folders.first();
    foreach (const CalendarFolder &f, folders) {
        if (!f.isReadOnly()) { targetFolder = f; break; }
    }

    foreach (const QVariant &gun, dataList) {
        QVariantMap gunMap = gun.toMap();
        QString dateStr = gunMap["date"].toString().left(10);
        QDate hedefTarih = QDate::fromString(dateStr, "yyyy-MM-dd");

        if (!hedefTarih.isValid() || hedefTarih < bugun || hedefTarih > birGunSonra) continue;

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

bool Service::getNotificationSetting(const QString &vakit, bool defaultValue) {
    return m_settings.value("notifications/" + vakit, defaultValue).toBool();
}
