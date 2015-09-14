import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.2
import Ubuntu.Components.ListItems 1.0
import Ubuntu.Content 0.1
import com.canonical.Oxide 1.0

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

    // Both the UserScript and the call to sendMessage need to share the same
    // context, which should be in the form of a URL.  It doesn't seem to matter
    // what it is, though.
    property string usContext: "messaging://"

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

    function addBookmark(url, title, icon, favorite) {
        openDatabase().transaction(function (tx) {
            tx.executeSql("INSERT OR REPLACE INTO Bookmarks(url, title, icon, created, favorite) " +
                          "VALUES(?, ?, ?, datetime('now'), ?)", [url, title, icon, favorite])
        })
    }

    function gotUrl(url) {
        loadIndicator.running = true;
        loadIndicator.visible = true;
        webview.url = url;
    }

    function receiveImport(items) {
        if (items.length != 1) {
            console.log("Got " + items.length + " shared items.  Don't know what to do....")
            return
        }
        root.gotUrl(items[0].url);
    }

    function listBookmarks(callback) {
        openDatabase().readTransaction(function (tx) {
            var res = tx.executeSql("SELECT url, title, icon, favorite FROM bookmarks " +
                                    "ORDER BY favorite DESC, length(title) > 0 DESC, title ASC")
            for (var i=0; i<res.rows.length; i++)
                callback(res.rows.item(i))
        })
    }

    Connections {
        target: ContentHub
        onShareRequested: {
            if (transfer.state == ContentTransfer.Charged)
                root.receiveImport(transfer.items)
        }
    }

    WebView {
        id: webview
        visible: false
        width:200
        height:200

        function chooseBestIcon(icons) {
            // pick the largest by size
            var by_size = [];
            icons.forEach(function(icon) {
                if (!icon.src) {
                    return;
                }
                if (icon.sizes) {
                    var parts = icon.sizes.split("x");
                    if (parts.length != 2) {
                        // sizes attribute should look like 256x256
                        return;
                    }
                    if (parts[0] != parts[1]) {
                        // all icons should be square
                        return
                    }
                    var size_as_num = parseInt(parts[0], 10);
                    if (isNaN(size_as_num)) {
                        return;
                    }
                    by_size.push([size_as_num, icon.src]);
                } else {
                    // doesn't specify a size
                    // so add it to the list, with lowest size
                    by_size.push([0, icon.src]);
                }
            });
            by_size.sort(function(b, a) {
                if (a[0] < b[0]) { return -1; }
                if (a[0] > b[0]) { return 1; }
                return 0;
            });
            if (by_size.length == 0) {
                return null;
            }
            return by_size[0][1];
        }

        onLoadingChanged: {
            console.log("webview loading", loading);
            if (loading == false) {
                var msg = webview.rootFrame.sendMessage(
                    root.usContext, "beginParsing", {}
                );
            }
        }
        context: WebContext {
            id: webcontext
            userScripts: [
                UserScript {
                    context: root.usContext
                    url: Qt.resolvedUrl("manifestParser.js")
                }
            ]
        }

        messageHandlers: [
            ScriptMessageHandler { 
                msgId: "endParsing"
                contexts: [root.usContext]
                callback: function(msg, frame) {
                    console.log("got message", JSON.stringify(msg.args));
                    loadIndicator.running = false;
                    loadIndicator.visible = false;
                    titleField.text = msg.args.short_name;
                    urlField.text = webview.url;
                    var best_src;
                    if (msg.args.icons && msg.args.icons.length > 1) {
                        best_src = webview.chooseBestIcon(msg.args.icons);
                    }
                    if (best_src) {
                        icon = best_src;
                    } else {
                        icon = Qt.resolvedUrl("graphics/addtodash.png");
                    }
                    pageContent.visible = true;
                }
            }
        ]

        onNavigationRequested: {
            request.action = 255; // block all navigation requests
            console.log("blocked request for", request.url);
        }

        preferences.allowScriptsToCloseWindows: false
        preferences.allowUniversalAccessFromFileUrls: false
        preferences.appCacheEnabled: false
        preferences.canDisplayInsecureContent: false
        preferences.canRunInsecureContent: false
        preferences.caretBrowsingEnabled: false
        preferences.databasesEnabled: false
        preferences.javascriptCanAccessClipboard: false
        preferences.javascriptEnabled: true /* need this or our userscript doesn't work, annoyingly */
        preferences.loadsImagesAutomatically: false
        preferences.localStorageEnabled: false
        preferences.passwordEchoEnabled: false
        preferences.remoteFontsEnabled: false
        preferences.shrinksStandaloneImagesToFit: false
        preferences.textAreasAreResizable: false
        preferences.touchEnabled: true
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
                root.listBookmarks(function (item) {
                    if (item.favorite)
                        favoriteBookmarks.append(item)
                    else
                        unsortedBookmarks.append(item)
                })
            }
            Component.onCompleted: loadBookmarks()

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
                    onClicked: stack.push(detailsPage,
                                              {url: model.url, bookmarkTitle: model.title,
                                              icon: model.icon || "", favorite: model.favorite})
                }
            }
        }

        Page {
            id: detailsPage
            visible: false

            title: i18n.tr("addtodash")
            property alias url: urlField.text
            property alias bookmarkTitle: titleField.text
            property string icon: ""
            property int favorite: 0

            function close(wasModified) {
                url = ""
                bookmarkTitle = ""
                icon = ""
                favorite = 0
                if (wasModified)
                    overviewPage.loadBookmarks()
                stack.pop()
            }

            ActivityIndicator {
                id: loadIndicator
                anchors.centerIn: parent
                running: false
                width: parent.width / 5
                height: parent.width / 5
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
                visible: true
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
                        addBookmark(detailsPage.url, detailsPage.bookmarkTitle, detailsPage.icon,
                                    detailsPage.favorite)
                        detailsPage.close(true)
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
                    root.gotUrl(urls[0]);
                }
            }
        }
    }
}
