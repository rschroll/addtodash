import QtQuick 2.0
import Ubuntu.Components 1.2

import Icon_Plugin 1.0

import "../shared/database.js" as Database

Page {
    id: detailsPage
    visible: false

    title: newUrl ? i18n.tr("Add Bookmark") : i18n.tr("Edit Bookmark")
    property string origUrl: ""
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
            if (url) {
                state = "loading"
                webview.url = url
            } else {
                state = "new"
            }
        } else {
            origUrl = url
            duplicateItem.visible = false
        }
    }

    HiddenWebView {
        id: webview

        function parsingCallback(msg, frame) {
            console.log("got message", JSON.stringify(msg.args));
            if (detailsPage.state == "loading") {
                detailsPage.bookmarkTitle = msg.args.short_name || ""
                detailsPage.icon = ""
                if (msg.args.icons && msg.args.icons.length)
                    downloader.setIcons(webview.getBestIcons(msg.args.icons))
                detailsPage.state = "editing"
            }
        }
    }

    IconDownloader {
        id: downloader
        property var iconList

        function setIcons(icons) {
            iconList = icons
            iconActivity.visible = true
            tryNextIcon()
        }

        function tryNextIcon() {
            var icon = iconList.shift()
            if (icon)
                download(icon)
            else
                iconActivity.visible = false
        }

        onDownloadError: {
            console.log("Download error: " + message)
            tryNextIcon()
        }

        onDownloadComplete: {
            detailsPage.icon = "file://" + filename
            iconActivity.visible = false
        }
    }

    Column {
        id: mainColumn
        spacing: units.gu(1)
        width: Math.min(parent.width, units.gu(50))
        anchors {
            margins: units.gu(2)
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        property real labelWidth: units.gu(8)

        Item {
            width: parent.width
            height: urlField.height

            Label {
                id: urlLabel
                text: i18n.tr("URL")
                width: mainColumn.labelWidth
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            TextField {
                id: urlField
                anchors {
                    left: urlLabel.right
                    right: editUrlButton.left
                }
                inputMethodHints:Qt.ImhUrlCharactersOnly
                readOnly: detailsPage.state != "new"

                onTextChanged: duplicateItem.state = ((text != origUrl && Database.hasUrl(text)) ?
                                                          "visible" : "hidden")
            }

            Button {
                id: editUrlButton
                width: visible ? units.gu(6) : 0
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                iconName: "edit"
                visible: detailsPage.state == "editing"

                onClicked: {
                    detailsPage.state = "new"
                    urlField.forceActiveFocus()
                }
            }
        }

        Item {
            id: duplicateItem
            width: parent.width
            state: "hidden"
            clip: true

            states: [
                State {
                    name: "hidden"
                    PropertyChanges {
                        target: duplicateItem
                        height: 0
                    }
                },
                State {
                    name: "visible"
                    PropertyChanges {
                        target: duplicateItem
                        height: duplicateLabel.height
                    }
                }
            ]

            Behavior on height {
                NumberAnimation {
                    easing.type: Easing.InOutQuad
                }
            }

            Icon {
                id: duplicateIcon
                name: "dialog-warning-symbolic"
                color: UbuntuColors.red
                anchors {
                    left: parent.left
                    leftMargin: mainColumn.labelWidth
                    verticalCenter: parent.verticalCenter
                }
                height: duplicateLabel.height
            }

            Label {
                id: duplicateLabel
                text: i18n.tr("Saved URL will be replaced.")
                anchors {
                    left: duplicateIcon.right
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                fontSize: "small"
                color: UbuntuColors.red
            }
        }

        Item {
            id: titleItem
            visible: detailsPage.state != "loading"
            width: parent.width
            height: titleField.height

            Label {
                id: titleLabel
                text: i18n.tr("Title")
                width: mainColumn.labelWidth
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            TextField {
                id: titleField
                anchors {
                    left: titleLabel.right
                    right: parent.right
                }
            }
        }

        Item {
            id: iconItem
            visible: detailsPage.state != "loading"
            width: parent.width
            height: iconShape.height

            Label {
                id: iconLabel
                text: i18n.tr("Icon")
                width: mainColumn.labelWidth
                anchors{
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }

            UbuntuShape {
                id: iconShape
                anchors.left: iconLabel.right
                source: Image {
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    source: detailsPage.icon ||
                            "file:///usr/share/icons/suru/actions/scalable/stock_website.svg"
                }
            }

            ActivityIndicator {
                id: iconActivity
                anchors.centerIn: iconShape
                visible: false
                running: visible
            }

            Button {
                width: parent.width/2 - units.gu(1)
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                text: i18n.tr("Load from page")
                visible: detailsPage.state == "new"

                onClicked: {
                    detailsPage.state = "loading"
                    webview.url = detailsPage.url
                }
            }
        }

        Item {
            id: buttonItem
            visible: detailsPage.state != "loading"
            height: childrenRect.height
            width: parent.width

            Button {
                width: parent.width/2 - units.gu(1)
                anchors.left: parent.left
                text: i18n.tr("Cancel")
                color: UbuntuColors.red

                onClicked: detailsPage.close(false)
            }

            Button {
                width: parent.width/2 - units.gu(1)
                anchors.right: parent.right
                text: i18n.tr("Save")
                color: UbuntuColors.green

                onClicked: {
                    Database.addBookmark(detailsPage.url, detailsPage.origUrl, detailsPage.bookmarkTitle,
                                         detailsPage.icon, detailsPage.favorite)
                    detailsPage.close(true)
                }
            }
        }

        Item {
            width: parent.width
            height: units.gu(20)
            visible: detailsPage.state == "loading"

            ActivityIndicator {
                id: indicator
                anchors {
                    top: parent.top
                    topMargin: units.gu(5)
                    horizontalCenter: parent.horizontalCenter
                }
                running: detailsPage.state == "loading"
            }

            Label {
                anchors {
                    top: indicator.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                text: i18n.tr("Loading page...")
            }

            Button {
                width: parent.width/2
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                text: i18n.tr("Cancel")
                color: UbuntuColors.red

                onClicked: detailsPage.state = "editing"
            }
        }
    }
}
