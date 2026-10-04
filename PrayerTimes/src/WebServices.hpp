#ifndef WEBSERVICES_HPP_
#define WEBSERVICES_HPP_

#include <QObject>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>
#include <bb/cascades/ArrayDataModel>
#include <bb/cascades/DataModel>
#include <QSettings>
#include <QVariantMap>
#include <QTimer>
#include <QTime>

class WebServices : public QObject {
    Q_OBJECT

    Q_PROPERTY(bb::cascades::DataModel* countryModel READ countryModel NOTIFY countryModelChanged)
    Q_PROPERTY(bb::cascades::DataModel* cityModel READ cityModel NOTIFY cityModelChanged)
    Q_PROPERTY(bb::cascades::DataModel* districtModel READ districtModel NOTIFY districtModelChanged)
    Q_PROPERTY(QVariantMap prayerTimes READ prayerTimes NOTIFY prayerTimesChanged)

    Q_PROPERTY(QString remainingTime READ remainingTime NOTIFY remainingTimeChanged)
    Q_PROPERTY(QString currentVakit READ currentVakit NOTIFY currentVakitChanged)
    Q_PROPERTY(QString selectedDistrictName READ selectedDistrictName NOTIFY selectedDistrictNameChanged)

    // UI tarafında donma sırasında loading göstermek için
    Q_PROPERTY(bool isBusy READ isBusy WRITE setBusy NOTIFY isBusyChanged)


public:
    WebServices(QObject *parent = 0);

    Q_INVOKABLE void fetchCountries();
    Q_INVOKABLE void fetchCities(const QString &countryId);
    Q_INVOKABLE void fetchDistricts(const QString &cityId);

    // --- Bildirim Ayarları (Toggle Button için yeni eklenenler) ---
    // Örn: saveNotification("imsak", true)

    // QML tarafında Toggle'ın başlangıç durumunu set etmek için kullanılır
    Q_INVOKABLE bool getNotificationSetting(const QString &vakit, bool defaultValue = false);

    bb::cascades::DataModel* countryModel() const { return m_countryModel; }
    bb::cascades::DataModel* cityModel() const { return m_cityModel; }
    bb::cascades::DataModel* districtModel() const { return m_districtModel; }

    Q_INVOKABLE void fetchPrayerTimes();
    Q_INVOKABLE void fetchPrayerTimesById(QString districtId);
    QVariantMap prayerTimes() const { return m_prayerTimes; }

    Q_INVOKABLE bool hasSavedLocation();

    QString remainingTime() const { return m_remainingTime; }
    QString currentVakit() const { return m_currentVakit; }
    QString selectedDistrictName() const {
        // m_settings kullanımı daha pratiktir
        return m_settings.value("selected_district_name", QString::fromUtf8("Konum Seçilmedi")).toString();
    }

    Q_INVOKABLE void scheduleNotifications(); // Vakitlere göre bildirimleri planlar
    Q_INVOKABLE void sendInstantNotification(const QString &title, const QString &body); // Test amaçlı
    Q_INVOKABLE QString getSavedValue(const QString &key);
    // BU SATIRI EKLE:
    Q_INVOKABLE void loadDataAndSchedule();
    Q_INVOKABLE void scheduleBatchNotifications(const QVariantList &dataList);
    Q_INVOKABLE void loadYearlyDataAndSchedule();
    Q_INVOKABLE void clearFutureCalendarEvents(const QString &vakitAdi = "");
    Q_INVOKABLE void saveAllSettings(const QVariantMap &settingsMap,
                                     const QVariantMap &reminderMap,
                                     const QVariantMap &durationMap,
                                     const QString &countryId,
                                     const QString &cityId,
                                     const QString &districtId,
                                     const QString &districtName);
    Q_INVOKABLE void saveAllSettingsAsync(const QVariantMap &r0, const QVariantMap &r1, const QVariantMap &dur, const QString &cId, const QString &cyId, const QString &dId, const QString &dName);
    Q_INVOKABLE void loadDataAndScheduleAsync(int delayMs);
    bool isBusy() const;
    void setBusy(bool busy);


signals:
    void countryModelChanged();
    void cityModelChanged();
    void districtModelChanged();
    void prayerTimesChanged();
    void remainingTimeChanged();
    void currentVakitChanged();
    void fetchComplete();
    void selectedDistrictNameChanged();
    void isBusyChanged();

private slots:
    void onCountriesReply();
    void onCitiesReply();
    void onDistrictsReply();
    void onPrayerTimesReply();
    void updateCountdown();
    void onTimerTimeout(); // Timer tetiklendiğinde çalışacak slot
    // Arka plan iş parçacığında çalışacak asıl işlem
    void backgroundScheduleTask();
    // Gecikmeli işlemler için yeni slotlar (Lambda hatasını çözer)
    void onAsyncSaveTriggered();
    void onAsyncLoadTriggered();
    void onGlobalSslErrors(QNetworkReply *reply, const QList<QSslError> &errors);


private:
    QNetworkAccessManager *m_networkManager;
    bb::cascades::ArrayDataModel *m_countryModel;
    bb::cascades::ArrayDataModel *m_cityModel;
    bb::cascades::ArrayDataModel *m_districtModel;

    QString m_serverUrl;
    QVariantMap m_prayerTimes;
    QString m_remainingTime;
    QString m_currentVakit;
    QTimer *m_timer;

    // QSettings'i burada tutmak disk erişimini yönetmeyi kolaylaştırır
    QSettings m_settings;

    void checkPrayerTimes(); // Her dakika çalışacak kontrol fonksiyonu
    bool m_isManualSaving;
    bool m_isBusy;

    // Geçici veri saklama (Async işlem için)
    QVariantMap m_tmpR0, m_tmpR1, m_tmpDur;
    QString m_tmpCId, m_tmpCyId, m_tmpDId, m_tmpDName;
};

#endif
