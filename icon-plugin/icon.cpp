#include "icon.h"

#include <QFile>
#include <QDir>
#include <QStandardPaths>
#include <QCryptographicHash>

#include <iostream>

IconDownloader::IconDownloader() {
    connect(&manager, SIGNAL(finished(QNetworkReply*)), SLOT(downloadCompleted(QNetworkReply*)));
    current = NULL;
    icon_dir = QStandardPaths::writableLocation(QStandardPaths::DataLocation) + "/icons/";
    QDir dir("");
    if (!dir.mkpath(icon_dir))
        std::cerr << "Error: Could not ensure icon directory exists" << std::endl;
}

void IconDownloader::download(const QString &url) {
    if (current)
        current->abort();

    current = manager.get(QNetworkRequest(QUrl(url)));
}

void IconDownloader::downloadCompleted(QNetworkReply *reply) {
    current = NULL;

    if (reply->error()) {
        emit downloadError(reply->errorString());
        return;
    }

    QString filename = icon_dir + QCryptographicHash::hash(reply->url().toEncoded(),
                                                           QCryptographicHash::Md5).toHex();
    QFile file(filename);
    if (!file.open(QIODevice::WriteOnly)) {
        emit downloadError("Could not open file for writing: " + filename);
        return;
    }

    file.write(reply->readAll());
    file.close();
    emit downloadComplete(filename);
}
