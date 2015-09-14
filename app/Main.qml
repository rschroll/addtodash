import QtQuick 2.0
import Ubuntu.Components 1.2
import Ubuntu.Components.ListItems 1.0
import Ubuntu.Content 0.1

import "database.js" as Database

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
                id: favoriteBookmarks
            }
            ListModel {
                id: unsortedBookmarks
            }

            function loadBookmarks() {
                favoriteBookmarks.clear()
                unsortedBookmarks.clear()
                Database.listBookmarks(function (item) {
                    if (item.favorite)
                        favoriteBookmarks.append(item)
                    else
                        unsortedBookmarks.append(item)
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

            Column {
                anchors.fill: parent

                Header {
                    id: favoriteHeader
                    text: i18n.tr("Favorites")
                }

                Item {
                    height: parent.height / 2 - favoriteHeader.height
                    width: parent.width
                    ListView {
                        anchors.fill: parent
                        model: favoriteBookmarks
                        delegate: bookmarkDelegate
                        clip: true
                    }
                }

                Header {
                    id: unsortedHeader
                    text: i18n.tr("Unsorted")
                }

                Item {
                    height: parent.height / 2 - unsortedHeader.height
                    width: parent.width
                    ListView {
                        anchors.fill: parent
                        model: unsortedBookmarks
                        delegate: bookmarkDelegate
                        clip: true
                    }
                }
            }

            Component {
                id: bookmarkDelegate
                Subtitled {
                    text: model.title
                    subText: model.url
                    icon: model.icon
                    fallbackIconName: "stock_website"
                    onClicked: stack.push(Qt.resolvedUrl("DetailsPage.qml"),
                                          {url: model.url, bookmarkTitle: model.title,
                                              icon: model.icon || "", favorite: model.favorite})
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
