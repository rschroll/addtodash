oxide.addMessageHandler("beginParsing", function (msg) {
    var parsed = {icons:[]};
    // Basic data
    var title = document.querySelector("title");
    if (title) {
        parsed.name = title.textContent;
        parsed.short_name = title.textContent.substr(0,12);
    }
    parsed.lang = document.getElementsByTagName("html")[0].getAttribute("lang") || "";
    // Apple touch icons
    [].slice.call(document.querySelectorAll('link[rel="apple-touch-icon"][href],link[rel="apple-touch-icon-precomposed"][href]')).forEach(function(l) {
        parsed.icons.push({src: l.getAttribute("href"), sizes: l.getAttribute("sizes")});
    });

    window.setTimeout(function() { 
        oxide.sendMessage("endParsing", parsed);
    }, 1);
});
