import QtQuick 2.0
import Ubuntu.Components 1.2

import "database.js" as Database

Page {
    id: detailsPage
    visible: false

    title: i18n.tr("addtodash")
    property alias url: urlField.text
    property alias bookmarkTitle: titleField.text
    property string icon: ""
    property int favorite: 0
    property bool newUrl: false
    property string state: "editing"

    function close(wasModified) {
        if (wasModified)
            overviewPage.loadBookmarks()
        stack.pop()
    }

    Component.onCompleted: {
        if (newUrl) {
            state = "loading"
            webview.url = url
        }
    }

    HiddenWebView {
        id: webview

        function parsingCallback(msg, frame) {
            console.log("got message", JSON.stringify(msg.args));
            bookmarkTitle = msg.args.short_name;
            if (msg.args.icons && msg.args.icons.length > 1)
                icon = webview.chooseBestIcon(msg.args.icons);
            detailsPage.state = "editing"
        }
    }

    ActivityIndicator {
        id: loadIndicator
        anchors.centerIn: parent
        width: parent.width / 5
        height: parent.width / 5
        visible: detailsPage.state == "loading"
        running: detailsPage.state == "loading"
    }

    Column {
        id: loadError
        spacing: units.gu(1)
        visible: false
        anchors {
            margins: units.gu(2)
            fill: parent
        }

        Label {
            text: "Failed to get page"
        }
    }

    Column {
        id: pageContent
        visible: detailsPage.state == "editing"
        spacing: units.gu(1)
        anchors {
            margins: units.gu(2)
            fill: parent
        }

        Label {
            text: i18n.tr("URL")
        }

        TextField {
            id: urlField
        }

        Label {
            text: i18n.tr("Title")
        }

        TextField {
            id: titleField
        }

        Label {
            text: i18n.tr("Icon") + " (we need to take a copy of this, not just show it)"
        }

        UbuntuShape {
            id: iconShape
            source: Image {
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                clip: true
                source: detailsPage.icon ||
                        "file:///usr/share/icons/suru/actions/scalable/stock_website.svg"
            }
        }

        Button {
            width: parent.width

            text: i18n.tr("Save")

            onClicked: {
                Database.addBookmark(detailsPage.url, detailsPage.bookmarkTitle,
                                     detailsPage.icon, detailsPage.favorite)
                detailsPage.close(true)
            }
        }
    }
}
