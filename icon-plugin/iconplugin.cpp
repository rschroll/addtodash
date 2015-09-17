#include <QtQml>
#include <QtQml/QQmlContext>
#include "icon.h"
#include "iconplugin.h"


void IconPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("Icon_Plugin"));

    qmlRegisterType<IconDownloader>(uri, 1, 0, "IconDownloader");
}

void IconPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    QQmlExtensionPlugin::initializeEngine(engine, uri);
}

