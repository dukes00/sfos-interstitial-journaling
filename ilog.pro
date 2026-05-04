# ilog — Interstitial Journal
# App name defined in TARGET has a corresponding QML filename.

TARGET = ilog

CONFIG += sailfishapp

SOURCES += src/ilog.cpp \
    src/journalstore.cpp

HEADERS += src/journalstore.h

DISTFILES += qml/ilog.qml \
    qml/pages/WritePage.qml \
    qml/cover/CoverPage.qml \
    rpm/ilog.changes.in \
    rpm/ilog.changes.run.in \
    rpm/ilog.spec \
    ilog.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172
