/* Copyright 2015 Robert Schroll
 *
 * This file is part of Browser Bookmarks Scope and is distributed under the
 * terms of the GPL. See the file LICENSE for full details.
 */

#include <client.h>
#include <sqlite3.h>
#include <iostream>

namespace Client {

std::string sqlite3_column_string(sqlite3_stmt *stmt, int col, std::string def) {
    const unsigned char *txt = sqlite3_column_text(stmt, col);
    if (txt == NULL)
        return def;
    std::string res(reinterpret_cast<const char*>(txt));
    if (res == "")
        return def;
    return res;
}

bool run_statement(std::string sql, sqlite3 **db, sqlite3_stmt **stmt) {
    if (sqlite3_open("/home/phablet/.local/share/addtodash.rschroll/Databases/7a69d6b27362b48011a2a09c56e04bce.sqlite", db)) {
        std::cerr << "Error opening database: " << sqlite3_errmsg(*db) << std::endl;
        return false;
    }

    if (sqlite3_prepare_v2(*db, sql.data(), -1, stmt, NULL)) {
        std::cerr << "Error preparing statement: " << sqlite3_errmsg(*db) << std::endl;
        return false;
    }

    return true;
}

BookmarkList get_bookmarks(std::string query, int sort) {
    BookmarkList bookmarks;

    sqlite3 *db;
    sqlite3_stmt *stmt;
    std::string sql = "SELECT url, title, icon, favorite FROM bookmarks";
    std::string sort_sql = " ORDER BY ";
    if (query != "")
        sql += " WHERE (url LIKE '%' || ? || '%' OR title LIKE '%' || ?1 || '%')";
    else
        sort_sql += "favorite DESC, ";
    if (sort == 0)
        sort_sql += "length(title) > 0 DESC, title ASC";
    else
        sort_sql += "created DESC";

    if (!run_statement(sql + sort_sql, &db, &stmt))
        goto exit;

    if (query != "") {
        if (sqlite3_bind_text(stmt, 1, query.data(), -1, SQLITE_STATIC)) {
            std::cerr << "Error binding text: " << sqlite3_errmsg(db) << std::endl;
            goto exit;
        }
    }

    {
        int res = sqlite3_step(stmt);
        while (res == SQLITE_ROW) {
            Bookmark b;
            b.url = sqlite3_column_string(stmt, 0, "");
            b.title = sqlite3_column_string(stmt, 1, b.url);
            b.icon = sqlite3_column_string(stmt, 2, "file:///usr/share/icons/suru/actions/scalable/stock_website.svg");
            b.favorite = sqlite3_column_double(stmt, 3);
            bookmarks.emplace_back(b);
            res = sqlite3_step(stmt);
        }
        if (res != SQLITE_DONE) {
            std::cerr << "Error reading rows: " << sqlite3_errmsg(db) << std::endl;
        }
    }

    exit:
    sqlite3_close(db);
    return bookmarks;
}

int get_container_id(std::string url) {
    int retval = -1;
    sqlite3 *db;
    sqlite3_stmt *stmt;
    if (!run_statement(CONTAINER_SQL, &db, &stmt))
        goto exit;

    if (sqlite3_bind_text(stmt, 1, url.data(), -1, SQLITE_STATIC)) {
        std::cerr << "Error binding text: " << sqlite3_errmsg(db) << std::endl;
        goto exit;
    }

    if (sqlite3_step(stmt))
        retval = sqlite3_column_int(stmt, 0);
    else
        std::cerr << "Error reading container id" << std::endl;

    exit:
    sqlite3_close(db);
    return retval;
}

}
