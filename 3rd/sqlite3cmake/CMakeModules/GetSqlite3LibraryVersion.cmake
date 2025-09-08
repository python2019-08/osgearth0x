function(GetSqlite3LibraryVersion _versionFile _major _minor _patch)
    # Read file content
    file(READ ${_versionFile} CONTENT)

    string(REGEX MATCH "([0-9]+)\\.([0-9]+)\\.([0-9]+)" VERSION_REGEX "${CONTENT}")
    set(${_major} ${CMAKE_MATCH_1} PARENT_SCOPE)
    set(${_minor} ${CMAKE_MATCH_2} PARENT_SCOPE)
    set(${_patch} ${CMAKE_MATCH_3} PARENT_SCOPE)
endfunction()

