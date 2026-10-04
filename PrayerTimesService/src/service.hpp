/*
 * Copyright (c) 2013-2015 BlackBerry Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef SERVICE_H_
#define SERVICE_H_

#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QNetworkAccessManager>
#include <QSettings>
#include <QTimer>

namespace bb {
    class Application;
    namespace platform {
        class Notification;
    }
    namespace system {
        class InvokeManager;
        class InvokeRequest;
    }
}

class Service: public QObject
{
    Q_OBJECT
public:
    Service();
    virtual ~Service() {}
private slots:
    void handleInvoke(const bb::system::InvokeRequest &);
    void onTimeout();
    void onPrayerTimesReply();
    void onGlobalSslErrors(QNetworkReply *reply, const QList<QSslError> &errors);
    void onPrayerTimerFired();
    void scheduleNextPrayerTimer();

private:
    void triggerNotification();
    void handleCalendarForVakit(const QString &vakit, const QVariantMap &tomorrowsTimes, const QDate &bugunTarih);

    bb::platform::Notification * m_notify;
    bb::system::InvokeManager * m_invokeManager;

    void fetchPrayerTimes();
    void scheduleBatchNotifications(const QVariantList &dataList);
    QVariantMap m_prayerTimes;
    QString m_serverUrl;
    QNetworkAccessManager *m_networkManager;
    bool getNotificationSetting(const QString &vakit, bool defaultValue);
    QSettings m_settings;
    QTimer *m_prayerTimer;
    QString m_currentScheduledVakit;
    QVariantMap m_tomorrowsTimesForSchedule;
};

#endif /* SERVICE_H_ */
