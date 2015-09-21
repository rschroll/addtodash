project(addtodash C CXX)
cmake_minimum_required(VERSION 2.8.9)
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake" "${CMAKE_MODULE_PATH}")

# Do not remove this line, its required for the correct functionality of the Ubuntu-SDK
set(UBUNTU_MANIFEST_PATH "manifest.json.in" CACHE INTERNAL "Tells QtCreator location and name of the manifest file")

find_package(Qt5Core)
find_package(Qt5Qml)
find_package(Qt5Quick)
# Find_package(ubuntu-sdk-libs)
find_package(PkgConfig)
find_package(Intltool)

#automatically create moc files
set(CMAKE_AUTOMOC ON)

# Figure out the component install path
execute_process(
    COMMAND dpkg-architecture -qDEB_HOST_MULTIARCH
    OUTPUT_VARIABLE ARCH_TRIPLET
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

# This command figures out the target architecture for use in the manifest file
execute_process(
    COMMAND dpkg-architecture -qDEB_HOST_ARCH
    OUTPUT_VARIABLE CLICK_ARCH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

set(QT_IMPORTS_DIR "lib/${ARCH_TRIPLET}")

set(APP_NAME          addtodash)
set(APP_ID            "addtodash.rschroll")
set(ADDTODASH_DIR "share/qml/addtodash")
set(CONTAINER_DIR "share/qml/container")
set(SHARED_DIR "share/qml/shared")
set(MAIN_QML          "Main.qml")
set(ICON              "graphics/addtodash.png")
set(N_CONTAINERS 4)
# CMake for loops contain both ends of a range.  I didn't know such stupidity was possible.
math(EXPR N_MAX "${N_CONTAINERS} - 1")

# We're trying to find a container with the given URL.  If not, create a new one, if we're
# under the maximum number.  Otherwise, select the least-recently focused container,
set(CONTAINER_SQL "SELECT id FROM (SELECT * FROM containers WHERE url = ? UNION ALL SELECT count(*), 1, 1 FROM containers UNION ALL SELECT id, url, min(lastFocused) FROM containers) WHERE id < ${N_CONTAINERS} LIMIT 1")

set(SCOPE_INSTALL_DIR "/addtodash")
set(SCOPE_NAME        "${APP_ID}_addtodash-scope")

# Set install paths
set(CMAKE_INSTALL_PREFIX /)
set(DATA_DIR /)
set(DESKTOP_DIR ${DATA_DIR})
set(DESKTOP_FILE_NAME "addtodash.desktop")

# This sets the commandline that is executed on the device
set(EXEC "qmlscene $@ ${ADDTODASH_DIR}/${MAIN_QML}")
set(EXEC_CONTAINER "qmlscene %U ${CONTAINER_DIR}/${MAIN_QML}")

set(HOOKS "")
foreach(N RANGE ${N_MAX})
  set(HOOKS "${HOOKS},\n\"container-${N}\": {\"apparmor\": \"addtodash-container.apparmor\", \"desktop\": \"addtodash-container-${N}.desktop\", \"urls\": \"addtodash-container-${N}.url-dispatcher\"}")
endforeach(N)

# If we need to refer to the scope's name or package in code, these definitions will help
add_definitions(-DPACKAGE_NAME="${PACKAGE_NAME}")
add_definitions(-DAPP_ID="${APP_ID}")
add_definitions(-DSCOPE_NAME="${SCOPE_NAME}")
add_definitions(-DGETTEXT_PACKAGE="${GETTEXT_PACKAGE}")
add_definitions(-DN_CONTAINERS=${N_CONTAINERS})
add_definitions(-DCONTAINER_SQL="${CONTAINER_SQL}")

# Configures the manifest file. The manifest file describes the click package
# to the target system. All cmake variables that are defined at this point
# can be used in the manifest file and will be automatically replaced by cmake
configure_file(manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/manifest.json)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json
        DESTINATION ${CMAKE_INSTALL_PREFIX})

install(DIRECTORY "app/graphics" DESTINATION ${DATA_DIR})
install(FILES "addtodash.apparmor" DESTINATION ${DATA_DIR})
install(FILES "addtodash-scope.apparmor" DESTINATION ${DATA_DIR})
install(FILES "addtodash-container.apparmor" DESTINATION ${DATA_DIR})
install(FILES "addtodash.contenthub" DESTINATION ${DATA_DIR})
install(FILES "addtodash.url-dispatcher" DESTINATION ${DATA_DIR})

add_subdirectory(app)
add_subdirectory(po)
add_subdirectory(scope)
add_subdirectory(container)
add_subdirectory(shared)
add_subdirectory(icon-plugin)

add_custom_target("run" /usr/bin/qmlscene -I ${CMAKE_BINARY_DIR}/backend  ${CMAKE_SOURCE_DIR}/app/addtodash.qml
                    WORKING_DIRECTORY ./app)

# Normally QtCreator would only show files that are part of a target, but we need it to show also files 
# that are not compiled. Therefore we add a custom target that just does nothing but list the files 
add_custom_target("addtodash_ClickFiles" ALL SOURCES
                  "addtodash.apparmor"
                  "addtodash-scope.apparmor"
                  "addtodash-container.apparmor"
                  "addtodash.contenthub"
                  "addtodash.url-dispatcher"
                  "manifest.json.in"
                  "scope/data/addtodash.ini.in"
                  "scope/data/addtodash-settings.ini.in")

