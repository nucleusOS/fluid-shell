#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QImage>
#include <QProcess>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QVariantMap>
#include <QIcon>
#include <QScreen>
#include <QQuickWindow>
#include <qdiriterator.h>
#include <QSettings>
#include "image_provider.h"
#include "process.h"
#include "battery_handler.h"

struct AppInfo {
    QString name;
    QString icon = "application";
    QString exec;
};

constexpr auto DESKTOP_FILE_SYSTEM_DIR = "/usr/share/applications";
constexpr auto DESKTOP_FILE_USER_DIR = "%1/.local/share/applications";
constexpr auto DESKTOP_ENTRY_STRING = "Desktop Entry";

class AppReader {
public:
    AppReader(QSettings &settings, const QString &groupName)
            : m_settings(settings) {
        m_settings.beginGroup(groupName);
    }

    ~AppReader() {
        m_settings.endGroup();
    }

private:
    QSettings &m_settings;
};

QVariantList createAppsList(const QString &path) {
    QDirIterator it(path, {"*.desktop"}, QDir::NoFilter, QDirIterator::Subdirectories);
    QVariantList ret;

    while (it.hasNext()) {
        const auto filename = it.next();
        QSettings desktopFile(filename, QSettings::IniFormat);

        if (!desktopFile.childGroups().contains(DESKTOP_ENTRY_STRING))
            continue;

        AppReader reader(desktopFile, DESKTOP_ENTRY_STRING);

        AppInfo app;
        app.exec = desktopFile.value("Exec").toString().remove("\"").remove(QRegExp(" %."));
        app.icon = desktopFile.value("Icon", "application").toString();

        if (desktopFile.value("Name").toString().length() > 14){
            QString short_value = desktopFile.value("Name").toString().mid(0,14);
            short_value.append("...");
            app.name = short_value;
        } else {
            app.name = desktopFile.value("Name").toString();
        }
        if(desktopFile.value("NoDisplay") != "true" && desktopFile.value("Hidden") != "true") {
            ret.append(QStringList{app.name, app.icon, app.exec});
        }

    }

    return ret;
}
QVariantList apps() {
    QVariantList ret;
    ret.append(createAppsList(DESKTOP_FILE_SYSTEM_DIR));
    ret.append(createAppsList(QString(DESKTOP_FILE_USER_DIR).arg(QDir::homePath())));
    return ret;
}

int main(int argc, char *argv[]) {
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    engine.setOfflineStoragePath(QDir::homePath() + "/.fluid/");
    engine.addImageProvider("icons", new ImageProvider());
    auto offlineStoragePath = QUrl::fromLocalFile(engine.offlineStoragePath());
    engine.rootContext()->setContextProperty("offlineStoragePath", offlineStoragePath);
    engine.rootContext()->setContextProperty("apps", apps());
    engine.rootContext()->setContextProperty("proc", new Process(&engine));
    engine.rootContext()->setContextProperty("battery_handler", new battery_handler());

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);
    return app.exec();
}
