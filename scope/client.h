#ifndef CLIENT_H_
#define CLIENT_H_

#include <atomic>
#include <deque>
#include <map>
#include <memory>
#include <string>

namespace Client {

struct Bookmark {
    std::string url;
    std::string title;
    std::string icon;
    double favorite;
};

typedef std::deque<Bookmark> BookmarkList;

BookmarkList get_bookmarks(std::string query, int sort);

int get_container_id(std::string url);

}

#endif // CLIENT_H_

