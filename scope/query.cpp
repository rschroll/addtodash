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

namespace sc = unity::scopes;

using namespace std;


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
        },
        "subtitle": "subtitle"
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
        sc::CategorisedResult res(bookmark.favorite ? fav_cat : all_cat);
        res.set_uri(bookmark.url);
        res.set_title(bookmark.title);
        res.set_art(bookmark.icon);
        res.set_intercept_activation();

        if (!reply->push(res)) {
            // Query has been cancelled.
            return;
        }
    }
}

