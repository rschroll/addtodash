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
                      "created INT, favorite INT DEFAULT 0, webapp INT DEFAULT 0)");
        tx.executeSql("CREATE TABLE IF NOT EXISTS Containers(id INT UNIQUE, url TEXT, " +
                      "lastFocused INT)");
    })
}

function addBookmark(url, title, icon, favorite) {
    openDatabase().transaction(function (tx) {
        tx.executeSql("INSERT OR REPLACE INTO Bookmarks(url, title, icon, created, favorite) " +
                      "VALUES(?, ?, ?, datetime('now'), ?)", [url, title, icon, favorite])
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

function saveContainerState(id, url) {
    openDatabase().transaction(function (tx) {
        tx.executeSql("INSERT OR REPLACE INTO Containers(id, url, lastFocused) " +
                      "VALUES(?, ?, datetime('now'))", [id, url]);
    })
}

function getContainerId(url) {
    var retval = -1
    openDatabase().readTransaction(function (tx) {
        var res = tx.executeSql("@CONTAINER_SQL@", [url])
        if (res.rows.length != 1)
            console.log("Warning: Could not determine container to use.")
        else
            retval = res.rows.item(0).id
    })
    return retval
}
