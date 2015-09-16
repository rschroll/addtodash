oxide.addMessageHandler("beginParsing", function (msg) {
    function resolveURL(url) {
        // resolves a relative URL to an absolute URL
        var a = document.createElement("a");
        a.href = url;
        return a.href;
    }

    function returnData() {
        window.setTimeout(function() {
            oxide.sendMessage("endParsing", parsed);
        }, 1);
    }

    function getManifest(callback) {
        /* Note that items in a manifest overwrite those in HTML */
        var linkman = document.querySelector("link[rel=manifest][href]");
        if (!linkman) {
            callback();
            return;
        }
        var xhr = new XMLHttpRequest();
        xhr.open("GET", resolveURL(linkman.getAttribute("href")), true);
        var abt = setTimeout(function() {
            xhr.abort();
            callback();
        }, 3000);
        xhr.onload = function() {
            clearTimeout(abt);
            if (xhr.status != 200) {
                callback();
                return;
            }

            var manifest;
            try {
                manifest = JSON.parse(xhr.responseText);
            } catch(e) {
                callback();
                return;
            }
            for (var k in manifest) {
                parsed[k] = manifest[k];
                if (parsed.icons) {
                    parsed.icons.forEach(function(icon) {
                        icon.src = resolveURL(icon.src);
                    })
                }

                callback();
            }
        }
        xhr.send();
    }

    var parsed = {icons:[]};
    // Basic data
    var title = document.querySelector("title");
    if (title) {
        parsed.name = title.textContent;
        parsed.short_name = title.textContent.substr(0,12);
    }
    parsed.lang = document.getElementsByTagName("html")[0].getAttribute("lang") || "";
    // Apple touch icons
    var touchIconLinks = document.querySelectorAll(
        'link[rel="apple-touch-icon"][href]' + 
        ',' +
        'link[rel="apple-touch-icon-precomposed"][href]'
    );
    [].slice.call(touchIconLinks).forEach(function(l) {
        parsed.icons.push({
            src: resolveURL(l.getAttribute("href")),
            sizes: l.getAttribute("sizes"),
            priority: 3 // how much we value this icon. higher is better
        });
    });

    // get a tileappimage if one is present and in the HTML
    var mstile = document.querySelector('meta[name="msapplication-TileImage"][content]');
    if (mstile) {
        parsed.icons.push({src: resolveURL(mstile.getAttribute("content")), priority: 2});
    }

    // get a favicon if one is present and in the HTML
    var favicon = document.querySelector("link[rel~=icon][href]");
    if (favicon) {
        parsed.icons.push({src: resolveURL(favicon.getAttribute("href")), priority: 1});
    }


    // Look for a manifest
    getManifest(function() {
        returnData();
    });

});
