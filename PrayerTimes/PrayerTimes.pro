APP_NAME = PrayerTimes

LIBS += -lbb -lbbsystem
LIBS += -lbbplatform
CONFIG += qt warn_on cascades10
# JSON ve Veri işlemleri için bu kütüphane şarttır
QT += network
LIBS += -lbbdata
LIBS += -lbps
LIBS += -lbbpim
QT += cascades concurrent
include(config.pri)