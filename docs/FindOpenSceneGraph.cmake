# MyPrj/cmake/FindOpenSceneGraph.cmake
#
# 手动指定源码编译的 OSG 路径（替换为你的实际路径）
message(STATUS "..............osgearth/cmake/FindOpenSceneGraph.cmake;;;OpenSceneGraph_ROOT=${OpenSceneGraph_ROOT}\n")
# set(OpenSceneGraph_ROOT "/path/to/OpenSceneGraph/build/ubuntu")
set(OpenSceneGraph_ROOT "" CACHE PATH "Root directory of OpenSceneGraph distribution,e.g. /path/to/OpenSceneGraph/build/ubuntu")

# 强制设置头文件和库路径
set(OpenSceneGraph_INCLUDE_DIRS
    "${OpenSceneGraph_ROOT}/include"
    "${OpenSceneGraph_ROOT}/include/osg"
)

# # 查找所有需要的库文件（根据你的 OSG 组件列表调整）
# find_library(OSG_LIBRARY osg PATHS "${OpenSceneGraph_ROOT}/lib" NO_DEFAULT_PATH)
# find_library(OSGDB_LIBRARY osgDB PATHS "${OpenSceneGraph_ROOT}/lib" NO_DEFAULT_PATH)
# # ... 添加其他所需组件（osgViewer、osgUtil 等）
 
set(OSG_ANY_COMPONENT_MISSING FALSE)
message(STATUS "Requested components: ${OpenSceneGraph_FIND_COMPONENTS}")
# 遍历并查找每个组件
foreach(component ${OpenSceneGraph_FIND_COMPONENTS})
    message(STATUS "to find OSG component: ${component}")

    find_library(${component}_LIBRARY_DEBUG
        NAMES ${component}d
        PATHS "${OpenSceneGraph_ROOT}/lib"
        NO_DEFAULT_PATH
    )
    find_library(${component}_LIBRARY_RELEASE
        NAMES ${component}
        PATHS "${OpenSceneGraph_ROOT}/lib"
        NO_DEFAULT_PATH
    )

    if( ${component}_LIBRARY_DEBUG )
        list(APPEND OpenSceneGraph_LIBRARIES ${${component}_LIBRARY_DEBUG})
    elseif( ${component}_LIBRARY_RELEASE )
        list(APPEND OpenSceneGraph_LIBRARIES ${${component}_LIBRARY_RELEASE})   
    else()
        message(WARNING "Could not find OSG component: ${component}")
        set(OSG_ANY_COMPONENT_MISSING TRUE)
    endif()
endforeach()




# 检查是否找到所有库
if(NOT OSG_ANY_COMPONENT_MISSING)
    message(WARNING "Could find all OSG component,OpenSceneGraph_LIBRARIES=${OpenSceneGraph_LIBRARIES}")
    set(OPENSCENEGRAPH_LIBRARIES  ${OpenSceneGraph_LIBRARIES})
    set(OpenSceneGraph_FOUND TRUE)
else()
    set(OpenSceneGraph_FOUND FALSE)
endif()

# 标记为高级变量（可选）
mark_as_advanced(OpenSceneGraph_INCLUDE_DIRS OpenSceneGraph_LIBRARIES)