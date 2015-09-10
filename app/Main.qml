import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.1
import Ubuntu.Content 0.1

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

    // Removes the old toolbar and enables new features of the new header.
    useDeprecatedToolbar: false

    width: units.gu(100)
    height: units.gu(75)

    function openDatabase() {
        return LocalStorage.openDatabaseSync("Bookmarks", "1", "URLs to be shown in a scope", 1000000,
                                             onDatabaseCreated)
    }

    function onDatabaseCreated(db) {
        db.changeVersion(db.version, "1")
        db.transaction(function (tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS Bookmarks(url TEXT UNIQUE, title TEXT, " +
                          "folder TEXT DEFAULT '', icon BLOB DEFAULT '', manifest TEXT DEFAULT '', " +
                          "created INT, favorite INT DEFAULT 0, webapp INT DEFAULT 0)")
        })
    }

    function addBookmark(url, title, icon) {
        openDatabase().transaction(function (tx) {
            tx.executeSql("INSERT OR IGNORE INTO Bookmarks(url, title, icon, created) " +
                          "VALUES(?, ?, ?, datetime('now'))", [url, title, icon])
        })
    }

    function receiveImport(items) {
        if (items.length != 1) {
            console.log("Got " + items.length + " shared items.  Don't know what to do....")
            return
        }
        urlField.text = items[0].url
    }

    Connections {
        target: ContentHub
        onShareRequested: {
            if (transfer.state == ContentTransfer.Charged)
                root.receiveImport(transfer.items)
        }
    }

    Page {
        title: i18n.tr("addtodash")

        Column {
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
                text: i18n.tr("Icon")
            }

            Button {
                width: parent.width

                text: i18n.tr("Save")

                onClicked: {
                    addBookmark(urlField.text, titleField.text, "")
                    urlField.text = ""
                    titleField.text = ""
                }
            }
        }
    }
}

