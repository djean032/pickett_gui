#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "src/models/spectrumdata.h"
#include "src/plot/spectrumplotitem.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Register C++ types for QML (required for custom QQuickItem)
    qmlRegisterType<SpectrumData>("Pickett", 1, 0, "SpectrumData");
    qmlRegisterType<SpectrumPlotItem>("Pickett", 1, 0, "SpectrumPlotItem");

    QQmlApplicationEngine engine;

    // Create the shared data model and expose it to QML
    SpectrumData spectrumData;
    engine.rootContext()->setContextProperty("spectrumData", &spectrumData);

    const QUrl url(QStringLiteral("qrc:/qt/qml/Pickett/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
