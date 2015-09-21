#ifndef ICON_H
#define MYTYPE_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

class IconDownloader : public QObject
{
    Q_OBJECT
    QNetworkAccessManager manager;
    QNetworkReply *current;
    QString icon_dir;

public:
    IconDownloader();
    Q_INVOKABLE void download(const QString &url);

Q_SIGNALS:
    void downloadComplete(const QString filename);
    void downloadError(const QString message);

public slots:
    void downloadCompleted(QNetworkReply *reply);
};

#endif // ICON_H

