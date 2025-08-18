include(ExternalProject)

set(The3rd_INSTALL_DIR ${CMAKE_INSTALL_PREFIX}/3rd)

# --------------------------------------------------------------
# 在配置阶段立即执行清理和目录创建
execute_process(
    COMMAND ${CMAKE_COMMAND} -E echo "gm.....clean ${CMAKE_BINARY_DIR}/3rd/libpsl"
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/3rd/libpsl
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/3rd/libpsl
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    RESULT_VARIABLE libpsl_pre_config_result
    OUTPUT_QUIET  # 隐藏输出（可选）
)

if(NOT libpsl_pre_config_result EQUAL 0)
    message(FATAL_ERROR "Failed to prepare libpsl directory!")
endif()

ExternalProject_Add(
    libpsl 

    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libpsl  # 源码路径
    PREFIX ${CMAKE_BINARY_DIR}/3rd/libpsl  # 构建临时目录
    INSTALL_DIR ${The3rd_INSTALL_DIR} # 安装目录
 
    CONFIGURE_COMMAND 
        ${CMAKE_COMMAND} -E echo "gm.....libpsl CONFIGURE_COMMAND" &&
        <SOURCE_DIR>/autogen.sh && 
        <SOURCE_DIR>/configure 
            --prefix=${The3rd_INSTALL_DIR} 
            --disable-shared 
            --enable-static
    BUILD_COMMAND make
    INSTALL_COMMAND make install
    BUILD_IN_SOURCE 0  # 使用独立构建目录（避免污染源码）

    BUILD_BYPRODUCTS ${The3rd_INSTALL_DIR}/lib/libpsl.a  # 确保 CMake 能检测到生成的库
)

# --------------------------------------------------------------
# # 添加 ExternalProject 构建
execute_process(
    COMMAND ${CMAKE_COMMAND} -E echo "gm.....config  libjpeg-turbo" 
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    RESULT_VARIABLE libjpeg_pre_config_result
    OUTPUT_QUIET  # 隐藏输出（可选）
)

ExternalProject_Add(
    libjpeg-turbo
    SOURCE_DIR ${CMAKE_SOURCE_DIR}/3rd/libjpeg-turbo  # 指定本地源码路径
    PREFIX     ${CMAKE_BINARY_DIR}/3rd/libjpeg-turbo
    BINARY_DIR ${CMAKE_BINARY_DIR}/3rd/libjpeg-turbo   # 构建目录（建议放在 build 目录下）
    INSTALL_DIR ${The3rd_INSTALL_DIR} # 安装目录

    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${The3rd_INSTALL_DIR}  # 必须指定安装路径
        -DWITH_JPEG8=ON      # 启用 JPEG 8 兼容性
        -DENABLE_SHARED=OFF  # 默认构建静态库（如需动态库改为 ON）
        -DWITH_SIMD=ON       # 启用 SIMD 优化（需安装 NASM）
    BUILD_ALWAYS OFF         # 仅在源码变更时重新构建
)
