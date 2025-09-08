# Generate source groups so the files are properly sorted in IDEs like Xcode.
function(create_source_groups target)
    get_target_property(type ${target} TYPE)
    if(type AND type STREQUAL "INTERFACE_LIBRARY")
        get_target_property(sources ${target} INTERFACE_SOURCES)
    else()
        get_target_property(sources ${target} SOURCES)
    endif()
    foreach(file ${sources})
        get_filename_component(file "${file}" ABSOLUTE)
        string(REGEX REPLACE "^${CMAKE_SOURCE_DIR}/" "" group "${file}")
        get_filename_component(group "${group}" DIRECTORY)
        string(REPLACE "/" "\\" group "${group}")
        source_group("${group}" FILES "${file}")
    endforeach()
endfunction()


# Creates a library target for a vendored dependency
function(add_vendor_target NAME TYPE)
    set(INCLUDE_TYPE "INTERFACE")
    set(SOURCE_TYPE "INTERFACE")

    if (TYPE STREQUAL "STATIC" OR TYPE STREQUAL "SHARED")
        add_library(${NAME} ${TYPE} "${CMAKE_CURRENT_SOURCE_DIR}/cmake/empty.cpp")
        set(INCLUDE_TYPE "PUBLIC")
        set(SOURCE_TYPE "PRIVATE")
        set_target_properties(${NAME} PROPERTIES SOURCES "")
    else()
        add_library(${NAME} ${TYPE})
    endif()

    set_target_properties(${NAME} PROPERTIES INTERFACE_SOURCES "")

    file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/vendor/${NAME}/files.txt" FILES)
    foreach(FILE IN LISTS FILES)
        target_sources(${NAME} ${SOURCE_TYPE} "${CMAKE_CURRENT_SOURCE_DIR}/vendor/${NAME}/${FILE}")
    endforeach()
    
    target_include_directories(${NAME} SYSTEM ${INCLUDE_TYPE} "${CMAKE_CURRENT_SOURCE_DIR}/vendor/${NAME}/include")
    create_source_groups(${NAME})
endfunction()