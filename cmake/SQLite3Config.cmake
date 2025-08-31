# SQLite3Config.cmake
include(CMakeFindDependencyMacro)

# 设置库路径和头文件路径
set(SQLite3_INCLUDE_DIRS "${SQLite3_ROOT}/include")
set(SQLite3_LIBRARY "${SQLite3_ROOT}/lib/libsqlite3.a")
set(SQLite3_LIBRARIES ${SQLite3_LIBRARY} -lm -lz)  # 包含私有依赖

# 导出目标
add_library(SQLite3::SQLite3 UNKNOWN IMPORTED)
set_target_properties(SQLite3::SQLite3 PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${SQLite3_INCLUDE_DIRS}"
    IMPORTED_LOCATION "${SQLite3_LIBRARY}"
    INTERFACE_LINK_LIBRARIES "-lm -lz"
)

# 版本信息（从 sqlite3.pc 中提取）
set(SQLite3_VERSION "3.50.4")