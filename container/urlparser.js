/*
Code adapted from https://github.com/IonicaBizau/node-protocols,
                  https://github.com/IonicaBizau/node-parse-url,
                  https://github.com/sindresorhus/query-string

(Protocols, ParseURL)
The KINDLY License
Copyright (c) 2015 Ionică Bizău <bizauionica@gmail.com> (http://ionicabizau.net)

You have the permission to use this software, read its source code, modify and
redistribute it under the following terms:

 - if you want to use this software or include parts of its code in a
   closed-source or commercial project you should kindly ask the
   author (via a private message or email) and get a positive answer
 - this license should be included in the modified versions of this software
 - in case of redistributing modified copies, you are encouraged to clearly
   indicate that the copies are based on this work
 - if you think that your redistributed copy is awesome, you are encouraged to
   show the author of this software what you did and how you helped the others

You are free to install and use this software on as many machines as you want,
free of charge, making sure you met the terms above.

You are encouraged to kindly support the software and its author by:

 - sharing his/her work
 - reporting issues/bugs and asking for feature requests
 - donating money or any other things that can help the author
 - contribute on the software code by fixing bugs and adding features

(extract, parseQS, stringifyQS)
The MIT License (MIT)

Copyright (c) Sindre Sorhus <sindresorhus@gmail.com> (sindresorhus.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

function Protocols(input, first) {
    if (first === true) {
        first = 0;
    }
    var index = input.indexOf("://"), 
        splits = input.substring(0, index).split("+").filter(Boolean);
    if (typeof first === "number") {
        return splits[first];
    }
    return splits;
}

/**
 * ParseUrl
 * Parses the input url.
 *
 * @name ParseUrl
 * @function
 * @param {String} url The input url.
 * @return {Object} An object containing the following fields:
 *
 *  - `protocols` (Array): An array with the url protocols (usually it has one element).
 *  - `port` (null|Number): The domain port.
 *  - `resource` (String): The url domain (including subdomains).
 *  - `user` (String): The authentication user (usually for ssh urls).
 *  - `pathname` (String): The url pathname.
 *  - `hash` (String): The url hash.
 *  - `search` (String): The url querystring value.
 *  - `href` (String): The input url.
 */
function ParseUrl(url) {
    var output = {
            protocols: Protocols(url),
            port: null,
            resource: "",
            user: "",
            pathname: "",
            hash: "",
            search: "",
            href: url,
        },
        protocolIndex = url.indexOf("://"),
        resourceIndex = -1,
        splits = null,
        parts = null;

    if (protocolIndex !== -1) {
        url = url.substring(protocolIndex + 3);
    }

    parts = url.split("/");
    output.resource = parts.shift();

    // user@domain
    splits = output.resource.split("@");
    if (splits.length === 2) {
        output.user = splits[0];
        output.resource = splits[1];
    }


    // domain.com:port
    splits = output.resource.split(":");
    if (splits.length === 2) {
        output.resource = splits[0];
        output.port = parseInt(splits[1]);
        if (isNaN(output.port)) {
            output.port = null;
            parts.unshift(splits[1]);
        }
    }

    // Remove empty elements
    parts = parts.filter(Boolean);

    // Stringify the pathname
    output.pathname = "/" + parts.join("/");

    // #some-hash
    splits = output.pathname.split("#");
    if (splits.length === 2) {
        output.pathname = splits[0];
        output.hash = splits[1];
    }

    // ?foo=bar
    splits = output.pathname.split("?");
    if (splits.length === 2) {
        output.pathname = splits[0];
        output.search = splits[1];
    }

    output.qs = parseQS(output.search);

    return output;
}

var extract = function (str) {
    return str.split('?')[1] || '';
};

var parseQS = function (str) {
    if (typeof str !== 'string') {
        return {};
    }

    str = str.trim().replace(/^(\?|#|&)/, '');

    if (!str) {
        return {};
    }

    return str.split('&').reduce(function (ret, param) {
        var parts = param.replace(/\+/g, ' ').split('=');
        var key = parts[0];
        var val = parts[1];

        key = decodeURIComponent(key);

        // missing `=` should be `null`:
        // http://w3.org/TR/2012/WD-url-20120524/#collect-url-parameters
        val = val === undefined ? null : decodeURIComponent(val);

        if (!ret.hasOwnProperty(key)) {
            ret[key] = val;
        } else if (Array.isArray(ret[key])) {
            ret[key].push(val);
        } else {
            ret[key] = [ret[key], val];
        }

        return ret;
    }, {});
};

var stringifyQS = function (obj) {
    return obj ? Object.keys(obj).sort().map(function (key) {
        var val = obj[key];

        if (Array.isArray(val)) {
            return val.sort().map(function (val2) {
                return strictUriEncode(key) + '=' + strictUriEncode(val2);
            }).join('&');
        }

        return strictUriEncode(key) + '=' + strictUriEncode(val);
    }).filter(function (x) {
        return x.length > 0;
    }).join('&') : '';
};