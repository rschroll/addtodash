set(JS_FILE database.js)

# Make the files visible in qtcreator
add_custom_target(addtodash_shared_QMlFiles ALL SOURCES ${JS_FILE})

configure_file(${JS_FILE} ${CMAKE_CURRENT_BINARY_DIR}/${JS_FILE})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${JS_FILE} DESTINATION ${SHARED_DIR})
