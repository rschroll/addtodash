import QtQuick 2.0
import Ubuntu.Components 1.2
import Ubuntu.Components.ListItems 1.0
import Ubuntu.Content 0.1

import "../shared/database.js" as Database

/*!
    \brief MainView with Tabs element.
           First Tab has a single Label and
           second Tab has a single ToolbarAction.
*/

MainView {
    id: root
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "addtodash.rschroll"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    //automaticOrientation: true

    width: units.gu(100)
    height: units.gu(75)

    function edit(url) {
        stack.push(Qt.resolvedUrl("DetailsPage.qml"), {url: url, newUrl: true})
    }

    function receiveImport(items) {
        if (items.length != 1) {
            console.log("Got " + items.length + " shared items.  Don't know what to do....")
            return
        }
        root.edit(items[0].url);
    }

    Connections {
        target: ContentHub
        onShareRequested: {
            if (transfer.state == ContentTransfer.Charged)
                root.receiveImport(transfer.items)
        }
    }

    PageStack {
        id: stack
        Component.onCompleted: push(overviewPage)

        Page {
            id: overviewPage
            visible: false

            title: i18n.tr("Bookmarks")

            ListModel {
                id: bookmarks
            }

            function loadBookmarks() {
                bookmarks.clear()
                Database.listBookmarks(function (item) {
                    item.section = (item.favorite > 0) ? i18n.tr("Favorites") : i18n.tr("Unsorted")
                    bookmarks.append(item)
                })
            }
            Component.onCompleted: loadBookmarks()

            head.actions: [
                Action {
                    iconName: "add"
                    text: i18n.tr("Add Bookmark")
                    onTriggered: root.edit("")
                }
            ]

            ListView {
                anchors.fill: parent
                model: bookmarks
                delegate: bookmarkDelegate
                section.property: "section"
                section.delegate: headerDelegate
            }

            Component {
                id: headerDelegate
                Header {
                    text: section
                }
            }

            Component {
                id: bookmarkDelegate

                ListItem {
                    id: listItem
                    action: Action {
                        onTriggered: stack.push(Qt.resolvedUrl("DetailsPage.qml"),
                                                {url: model.url, bookmarkTitle: model.title,
                                                    icon: model.icon || "", favorite: model.favorite})
                    }

                    leadingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "delete"
                                onTriggered: {
                                    Database.removeUrl(model.url)
                                    listItem.ListView.view.model.remove(model.index)
                                }
                            }
                        ]
                    }

                    UbuntuShape {
                        id: iconHelper

                        width: height
                        height: Math.min(units.gu(5), parent.height - units.gu(1))
                        anchors {
                            left: parent.left
                            leftMargin: units.gu(2)
                            verticalCenter: parent.verticalCenter
                        }
                        source: Image {
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            clip: true
                            source: model.icon ||
                                    "file:///usr/share/icons/suru/actions/scalable/stock_website.svg"
                        }
                    }

                    Item  {
                        id: middleVisuals
                        anchors {
                            left: iconHelper.right
                            leftMargin: units.gu(2)
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        height: childrenRect.height + label.anchors.topMargin + subLabel.anchors.bottomMargin

                        Label {
                            id: label
                            text: model.title
                            color: Theme.palette.selected.backgroundText
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                            }
                        }
                        Label {
                            id: subLabel
                            text: model.url
                            color: Theme.palette.normal.backgroundText
                                anchors {
                                left: parent.left
                                right: parent.right
                                top: label.bottom
                            }
                            fontSize: "small"
                            wrapMode: Text.Wrap
                            maximumLineCount: 5
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        var urls = Array.prototype.slice.call(
                    Qt.application.arguments
                    ).filter(function(s) {
                        return s.match(/^https?:\/\//);
                    });
        if (urls.length === 1) {
            root.edit(urls[0]);
        }
    }
}
