# Searches for all qml and javascript files in the current directory
# to add them to the project, if you add new files in the directory
# rerun cmake to make sure they show up in the project tree
file(GLOB QML_JS_FILES *.qml *.js)
file(GLOB UCS_FILES UCSComponents/*.qml)

# Make the files visible in qtcreator
add_custom_target(addtodash_container_QMlFiles ALL SOURCES ${QML_JS_FILES} ${UCS_FILES}
                                                           addtodash-container.desktop.in
                                                           addtodash-container.url-dispatcher.in)

install(FILES ${QML_JS_FILES} DESTINATION ${CONTAINER_DIR})
install(FILES ${UCS_FILES} DESTINATION ${CONTAINER_DIR}/UCSComponents)

foreach(N RANGE ${N_MAX})
  configure_file(addtodash-container.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/addtodash-container-${N}.desktop)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/addtodash-container-${N}.desktop DESTINATION ${DESKTOP_DIR})

  configure_file(addtodash-container.url-dispatcher.in ${CMAKE_CURRENT_BINARY_DIR}/addtodash-container-${N}.url-dispatcher)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/addtodash-container-${N}.url-dispatcher DESTINATION ${DESKTOP_DIR})
endforeach(N)
