import QtQuick 2.2
import QtMultimedia 5.0
import QtFeedback 5.0
import Ubuntu.Components 1.1
import com.canonical.Oxide 1.0
import "UCSComponents"
import "."
//import "../config.js" as Conf
import "urlparser.js" as URLParser;

MainView {
    id: root
    objectName: "mainView"

    applicationName: "google-plus.ogra"

    useDeprecatedToolbar: false
    anchorToKeyboard: true
    automaticOrientation: true

    property int myNumber: 1
    property string pattern: ".*"

    function parseAndLoad(executeURL) {
        /*
        The executeURL looks like this:
        addtodash-container-1:///ignored?url=http%3A%2F%2Fwww.ubuntu.com%2F&...
        (note three slashes)
        All parameters are URI-encoded (as expected), and are from the list below
        The url parameter is required; all others are optional.
        url: the URL to open in the webview
        pattern: a URL pattern to match; opening a URL which does not match this
            pattern will open it in the browser instead
        */
        var parsed = URLParser.ParseUrl(executeURL);
        if (!parsed.qs || !parsed.qs.url) {
            console.log("No actual URL passed");
            return;
        }
        webview.url = parsed.qs.url;
    }

    Page {
        id: page
        anchors {
            fill: parent
            bottom: parent.bottom
        }
        width: parent.width
        height: parent.height

        HapticsEffect {
            id: vibration
            attackIntensity: 0.0
            attackTime: 50
            intensity: 1.0
            duration: 10
            fadeTime: 50
            fadeIntensity: 0.0
        }

        /*
        SoundEffect {
            id: clicksound
            source: "../sounds/Click.wav"
        }
        */

        WebView {
            id: webview
            anchors {
                fill: parent
                bottom: parent.bottom
            } 
            width: parent.width
            height: parent.height

            preferences.localStorageEnabled: true
            preferences.appCacheEnabled: true
            preferences.javascriptCanAccessClipboard: true
            filePicker: filePickerLoader.item

            function navigationRequestedDelegate(request) {
                var url = request.url.toString();
                var pattern = root.pattern.split(',');
                var isvalid = false;

                /*
                if (Conf.hapticLinks) {
                    vibration.start()
                }

                if (Conf.audibleLinks) {
                    clicksound.play()
                }
                */

                for (var i=0; i<pattern.length; i++) {
                    var tmpsearch = pattern[i].replace(/\*/g,'(.*)')
                    var search = tmpsearch.replace(/^https\?:\/\//g, '(http|https):\/\/');
                    if (url.match(search)) {
                       isvalid = true;
                       break
                    }
                } 
                if(isvalid == false) {
                    console.warn("Opening remote: " + url);
                    Qt.openUrlExternally(url)
                    request.action = Oxide.NavigationRequest.ActionReject
                }
            }
            Component.onCompleted: {
                preferences.localStorageEnabled = true
                //if (Qt.application.arguments[1].toString().indexOf(myUrl) > -1) {
                //    console.warn("got argument: " + Qt.application.arguments[1])
                //    url = Qt.application.arguments[1]
                //}
                console.warn("url is: " + url)
            }
            onGeolocationPermissionRequested: { request.accept() }
            Loader {
                id: filePickerLoader
                //source: "ContentPickerDialog.qml"
                asynchronous: true
            }
        }
        ThinProgressBar {
            webview: webview
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
        }
        RadialBottomEdge {
            id: nav
            visible: true
            actions: [
                RadialAction {
                    id: reload
                    iconName: "reload"
                    onTriggered: {
                        webview.reload()
                    }
                    text: qsTr("Reload")
                },
                RadialAction {
                    id: forward
                    enabled: webview.canGoForward
                    iconName: "go-next"
                    onTriggered: {
                        webview.goForward()
                    }
                   text: qsTr("Forward")
                 },
                RadialAction {
                    id: back
                    enabled: webview.canGoBack
                    iconName: "go-previous"
                    onTriggered: {
                        webview.goBack()
                    }
                    text: qsTr("Back")
                }
            ]
        }
    }
    Connections {
        target: Qt.inputMethod
        onVisibleChanged: nav.visible = !nav.visible
    }
    Connections {
        target: webview
        onFullscreenChanged: nav.visible = !webview.fullscreen
    }
    Connections {
        target: UriHandler
        onOpened: {
            if (uris.length === 0 ) {
                return;
            }
            // we are already open, so open this one in the next container
            var parsed = uris[0].match(/^(addtodash-container-)([0-9]+)(:\/\/\/.*)$/);
            var outurl = "addtodash-container-" + (root.myNumber+1) + parsed[3];
            Qt.openUrlExternally(outurl);
            console.log("Container " + root.myNumber + " got URI request " + 
                uris[0] + " and passed it on as " + outurl);
        }
    }

    Component.onCompleted: {
        // On startup, get the URL we were called with
        var args = Array.prototype.slice.call(
                    Qt.application.arguments
                );
        var urls = args.filter(function(s) {
            return s.match(/^addtodash-container-[0-9]+:\/\//);
        });
        root.myNumber = parseInt(args[args.length-1], 10);
        if (urls.length > 0) {
            console.log("Container " + root.myNumber + " got URI request " + 
                urls[0] + " and opened it");
                root.parseAndLoad(urls[0]);
        } else {
            console.log("Container " + root.myNumber + " was started with no URL, weirdly;" +
                " args were " + JSON.stringify(args));
        }
    }
}