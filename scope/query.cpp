/* Copyright 2015 Robert Schroll
 *
 * This file is part of Browser Bookmarks Scope and is distributed under the
 * terms of the GPL. See the file LICENSE for full details.
 */

#include <query.h>
#include <localization.h>

#include <unity/scopes/Annotation.h>
#include <unity/scopes/CategorisedResult.h>
#include <unity/scopes/CategoryRenderer.h>
#include <unity/scopes/QueryBase.h>
#include <unity/scopes/SearchReply.h>

#include <iostream>
#include <iomanip>
#include <sstream>

namespace sc = unity::scopes;

using namespace std;


// From http://stackoverflow.com/questions/154536/encode-decode-urls-in-c
string url_encode(const string &value) {
    ostringstream escaped;
    escaped.fill('0');
    escaped << hex;

    for (string::const_iterator i = value.begin(), n = value.end(); i != n; ++i) {
        string::value_type c = (*i);

        // Keep alphanumeric and other accepted characters intact
        if (isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') {
            escaped << c;
            continue;
        }

        // Any other characters are percent-encoded
        escaped << '%' << uppercase << setw(2) << int((unsigned char) c);
    }

    return escaped.str();
}

const static string BOOKMARK_TEMPLATE =
        R"(
{
        "schema-version": 1,
        "template": {
        "category-layout": "grid",
        "card-size": "small"
        },
        "components": {
        "title": "title",
        "art" : {
        "field": "art"
        }
        }
        }
        )";

const static string MANAGEMENT_TEMPLATE =
        R"(
{
        "schema-version": 1,
        "template": {
        "category-layout": "grid",
        "card-layout": "vertical",
        "card-size": "large",
        "card-background": "color:///white"
        },
        "components": {
        "title": "title",
        "mascot": "art"
        }
        }
        )";

Query::Query(const sc::CannedQuery &query, const sc::SearchMetadata &metadata) :
    sc::SearchQueryBase(query, metadata) {
}

void Query::cancelled() {
}


void Query::run(sc::SearchReplyProxy const& reply) {
    // Start by getting information about the query
    const sc::CannedQuery &query(sc::SearchQueryBase::query());

    int sort = settings().at("sort").get_int();
    bool has_query = (query.query_string() != "");
    Client::BookmarkList bookmarks =
            Client::get_bookmarks(query.query_string(), sort);

    if (!bookmarks.size())
        // Explanatory text
        return;

    auto fav_cat = reply->register_category("favorites", "", "",
                                            sc::CategoryRenderer(BOOKMARK_TEMPLATE));
    // Check to see if any bookmarks have been favorited (they come first)
    bool areFavorites = (bookmarks[0].favorite > 0);
    // No need for a label if no bookmarks are favorited
    auto all_cat = reply->register_category("bookmarks", areFavorites ? _("Unsorted") : "", "",
                                            sc::CategoryRenderer(BOOKMARK_TEMPLATE));

    for (const Client::Bookmark bookmark : bookmarks) {
        // If running a query, don't put results into different categories.
        sc::CategorisedResult res((bookmark.favorite || has_query) ? fav_cat : all_cat);
        res.set_uri(bookmark.url);
        if (bookmark.url.substr(0, 4) == "http") {
            int n = Client::get_container_id(bookmark.url);
            if (n >= 0) {
                ostringstream url;
                url << "addtodash://container-" << n
                    << "/?url=" << url_encode(bookmark.url);
                res.set_uri(url.str());
                res.set_title(std::to_string(n) + ": " + bookmark.title);
            }
        }
//        res.set_title(bookmark.title);
        res.set_art(bookmark.icon);
        res.set_intercept_activation();

        if (!reply->push(res)) {
            // Query has been cancelled.
            return;
        }
    }

    if (!has_query) {
        auto management_cat = reply->register_category("management", "", "",
                                                       sc::CategoryRenderer(MANAGEMENT_TEMPLATE));
        sc::CategorisedResult res(management_cat);
        res.set_title(_("Manage Bookmarks"));
        res.set_art("file:///opt/click.ubuntu.com/" APP_ID "/current/graphics/addtodash.png");
        res.set_uri("addtodash://manage");
        res.set_intercept_activation();
        reply->push(res);
    }
}

