//.pragma library
.import QtQuick.LocalStorage 2.0 as Sql

function openDatabase() {
    return Sql.LocalStorage.openDatabaseSync("Bookmarks", "1", "URLs to be shown in a scope", 1000000,
                                         onDatabaseCreated)
}

function onDatabaseCreated(db) {
    db.changeVersion(db.version, "1")
    db.transaction(function (tx) {
        tx.executeSql("CREATE TABLE IF NOT EXISTS Bookmarks(url TEXT UNIQUE, title TEXT, " +
                      "folder TEXT DEFAULT '', icon BLOB DEFAULT '', manifest TEXT DEFAULT '', " +
                      "created INT, favorite REAL DEFAULT 0, webapp INT DEFAULT 0)");
        tx.executeSql("CREATE TABLE IF NOT EXISTS Containers(myNumber INT UNIQUE, url TEXT, " +
                      "lastFocused INT)");
    })
}

function addBookmark(url, origUrl, title, icon, favorite) {
    openDatabase().transaction(function (tx) {
        if (origUrl != "" && origUrl != "url")
            tx.executeSql("DELETE FROM Bookmarks WHERE url = ?", [origUrl])

        if (favorite < 0) {  // Indicates this bookmark should become least favorite
            var res = tx.executeSql("SELECT favorite FROM Bookmarks WHERE favorite > 0 " +
                                    "ORDER BY favorite ASC")
            if (res.rows.length)
                favorite = res.rows.item(0).favorite / 2
            else
                favorite = 1
        }

        tx.executeSql("INSERT OR REPLACE INTO Bookmarks(url, title, icon, created, favorite) " +
                      "VALUES(?, ?, ?, datetime('now'), ?)", [url, title, icon, favorite])
    })
}

function setFavorite(url, favorite) {
    openDatabase().transaction(function (tx) {
        tx.executeSql("UPDATE Bookmarks SET favorite = ? WHERE url = ?", [favorite, url])
    })
}

function listBookmarks(callback) {
    openDatabase().readTransaction(function (tx) {
        var res = tx.executeSql("SELECT url, title, icon, favorite FROM bookmarks " +
                                "ORDER BY favorite DESC, length(title) > 0 DESC, title ASC")
        for (var i=0; i<res.rows.length; i++)
            callback(res.rows.item(i))
    })
}

function saveContainerState(url, myNumber) {
    openDatabase().transaction(function (tx) {
        tx.executeSql("INSERT OR REPLACE INTO Containers(myNumber, url, lastFocused) " +
                      "VALUES(?, ?, datetime('now'))", [myNumber, url]);
    })
}

function hasUrl(url) {
    var retval = false;
    openDatabase().readTransaction(function (tx) {
        var res = tx.executeSql("SELECT url FROM Bookmarks WHERE url = ?", [url])
        retval = (res.rows.length > 0)
    })
    return retval
}

function removeUrl(url) {
    openDatabase().transaction(function (tx) {
        tx.executeSql("DELETE FROM Bookmarks WHERE url = ?", [url])
    })
}
