include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
)

set(
    Icon_Plugin_SRCS
    iconplugin.cpp
    icon.cpp
)

# Make the unit test files visible on qtcreator
add_custom_target(plugin_qmldir ALL SOURCES qmldir)

add_library(Icon_Plugin MODULE
    ${Icon_Plugin_SRCS}
)

set_target_properties(Icon_Plugin PROPERTIES
         LIBRARY_OUTPUT_DIRECTORY Icon_Plugin)

qt5_use_modules(Icon_Plugin Gui Qml Quick)

# Copy qmldir file to build dir for running in QtCreator
add_custom_target(Icon_Plugin-qmldir ALL
    COMMAND cp ${CMAKE_CURRENT_SOURCE_DIR}/qmldir ${CMAKE_CURRENT_BINARY_DIR}/Icon_Plugin
    DEPENDS ${QMLFILES}
)

# Install plugin file
install(TARGETS Icon_Plugin DESTINATION ${QT_IMPORTS_DIR}/Icon_Plugin/)
install(FILES   qmldir DESTINATION ${QT_IMPORTS_DIR}/Icon_Plugin/)

