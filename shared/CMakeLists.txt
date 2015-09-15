# Searches for all qml and javascript files in the current directory
# to add them to the project, if you add new files in the directory
# rerun cmake to make sure they show up in the project tree
file(GLOB_RECURSE QML_JS_FILES *.qml *.js)

# Make the files visible in qtcreator
add_custom_target(addtodash_shared_QMlFiles ALL SOURCES ${QML_JS_FILES})

install(FILES ${QML_JS_FILES} DESTINATION ${SHARED_DIR})
