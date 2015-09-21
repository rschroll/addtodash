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

    function iconLinks(selector, priority) {
        var links = document.querySelectorAll("link[" + selector + "][href]");
        [].slice.call(links).forEach(function (l) {
            parsed.icons.push({
                src: resolveURL(l.getAttribute("href")),
                sizes: l.getAttribute("sizes"),
                priority: priority  // how much we value this icon. higher is better
            });
        });
    }

    // Apple touch icons
    iconLinks('rel="apple-touch-icon"', 3);
    iconLinks('rel="apple-touch-icon-precomposed"', 3);

    // get a tileappimage if one is present and in the HTML
    var mstile = document.querySelector('meta[name="msapplication-TileImage"][content]');
    if (mstile) {
        parsed.icons.push({src: resolveURL(mstile.getAttribute("content")), priority: 2});
    }

    // get a favicon if one is present and in the HTML
    iconLinks("rel~=icon", 1);

    // And try the /favicon.ico file if nothing else
    parsed.icons.push({src: resolveURL("/favicon.ico"), priority: 0});

    // Look for a manifest
    getManifest(function() {
        returnData();
    });

});
