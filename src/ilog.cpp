#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include <QScopedPointer>
#include <QGuiApplication>
#include <QQuickView>
#include <QtQml>

#include "journalstore.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    qmlRegisterType<JournalStore>("org.duke.ilog", 1, 0, "JournalStore");

    view->setSource(SailfishApp::pathTo("qml/ilog.qml"));
    view->show();

    return app->exec();
}
