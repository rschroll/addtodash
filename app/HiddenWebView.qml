import QtQuick 2.0
import com.canonical.Oxide 1.0

WebView {
    id: webview
    visible: false
    width:200
    height:200

    // Both the UserScript and the call to sendMessage need to share the same
    // context, which should be in the form of a URL.  It doesn't seem to matter
    // what it is, though.
    property string usContext: "messaging://"

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
                // priority 100 because this actually has a size
                // strictly not necessary (sizes come before no size)
                by_size.push({size: size_as_num, priority:100, src:icon.src});
            } else {
                // doesn't specify a size
                // so add it to the list, with lowest size
                by_size.push({size:0, priority:icon.priority || 0, src:icon.src});
            }
        });
        if (by_size.length == 0) {
            return null;
        }
        by_size.sort(function(b, a) {
            if (a.size < b.size) { return -1; }
            if (a.size > b.size) { return 1; }
            if (a.priority < b.priority) { return -1; }
            if (a.priority > b.priority) { return 1; }
            return 0;
        });
        return by_size[0].src;
    }

    onLoadingChanged: {
        console.log("webview loading", loading);
        if (loading == false) {
            var msg = webview.rootFrame.sendMessage(
                webview.usContext, "beginParsing", {}
            );
        }
    }
    context: WebContext {
        id: webcontext
        userScripts: [
            UserScript {
                context: webview.usContext
                url: Qt.resolvedUrl("manifestParser.js")
            }
        ]
    }

    messageHandlers: [
        ScriptMessageHandler {
            msgId: "endParsing"
            contexts: [webview.usContext]
            callback: parsingCallback
        }
    ]

    /* For now, allow hidden pages to navigate themselves elsewhere. Review this;
       ideally we wouldn't allow a page to jump somewhere else, but we need to
       correctly handle things like a URL of http://example.org/thing
       which redirects to http://example.org/thing/ with a slash, or to
       https://example.org/thing to be over SSL.
    onNavigationRequested: {
        request.action = 255; // block all navigation requests
        console.log("blocked request for", request.url, "when url is", url);
    }
    */

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
