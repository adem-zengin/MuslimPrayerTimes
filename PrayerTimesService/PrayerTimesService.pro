APP_NAME = PrayerTimesService

CONFIG += qt warn_on

include(config.pri)

LIBS += -lbb -lbbsystem -lbbplatform
QT += core network
LIBS += -lbbdata
LIBS += -lbps
LIBS += -lbbpim
QT += concurrent
QT += cascades
