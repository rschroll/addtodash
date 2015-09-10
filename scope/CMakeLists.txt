# We require at least g++ 4.9, to avoid ABI breakage with earlier versions.
set(cxx_version_required 4.9)
if (CMAKE_COMPILER_IS_GNUCXX)
    if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${cxx_version_required})
        message(FATAL_ERROR "g++ version must be at least ${cxx_version_required}!")
    endif()
endif()

# Set strict and naggy C++ compiler flags, and enable C++11
add_definitions(
  -fno-permissive
  -std=c++11
  -pedantic
  -Wall
  -Wextra
  -fPIC
  -DQT_NO_KEYWORDS
)

pkg_check_modules(
  SCOPE
  libunity-scopes>=0.6.0
  sqlite3
  REQUIRED
)

# Add our dependencies to the include paths
include_directories(
  "${CMAKE_SOURCE_DIR}/scope"
  ${SCOPE_INCLUDE_DIRS}
)

# If we need to refer to the scope's name or package in code, these definitions will help
add_definitions(-DPACKAGE_NAME="${PACKAGE_NAME}")
add_definitions(-DSCOPE_NAME="${SCOPE_NAME}")
add_definitions(-DGETTEXT_PACKAGE="${GETTEXT_PACKAGE}")

# Put the ini files in the build directory next to the scope
# .so file so that the test tools can find them.
intltool_merge_translations(
  "data/addtodash.ini.in"
  "${CMAKE_CURRENT_BINARY_DIR}/${SCOPE_NAME}.ini"
  ALL
  UTF8
)
intltool_merge_translations(
  "data/addtodash-settings.ini.in"
  "${CMAKE_CURRENT_BINARY_DIR}/${SCOPE_NAME}-settings.ini"
  ALL
  UTF8
)

# Install the scope ini files
install(
  FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${SCOPE_NAME}.ini"
    "${CMAKE_CURRENT_BINARY_DIR}/${SCOPE_NAME}-settings.ini"
  DESTINATION
    ${SCOPE_INSTALL_DIR}
)

# Find all the sources
file(GLOB_RECURSE
  SCOPE_SOURCES
  "*.cpp"
  "*.h"
)

include_directories(SYSTEM /usr/include)

# Build a shared library containing our scope code.
add_library(
  scope SHARED
  ${SCOPE_SOURCES}
)

# Link against the object library and our external library dependencies
target_link_libraries(
  scope
  ${SCOPE_LDFLAGS}
)


# Set the correct library output name to conform to the securiry policy 
set_target_properties(
  scope
  PROPERTIES
    OUTPUT_NAME "${SCOPE_NAME}"
)

# Install the scope shared library
install(
  TARGETS scope
  LIBRARY DESTINATION ${SCOPE_INSTALL_DIR}
)

