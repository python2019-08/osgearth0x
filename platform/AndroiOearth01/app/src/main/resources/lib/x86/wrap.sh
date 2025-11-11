#!/system/bin/sh
# ----------------------------------------------------------------
# HERE="$(cd "$(dirname "$0")" && pwd)"
# export ASAN_OPTIONS=log_to_syslog=false,allow_user_segv_handler=1
# ASAN_LIB=$(ls $HERE/libclang_rt.asan-*-android.so)
# if [ -f "$HERE/libc++_shared.so" ]; then
#     # Workaround for https://github.com/android-ndk/ndk/issues/988.
#     export LD_PRELOAD="$ASAN_LIB $HERE/libc++_shared.so"
# else
#     export LD_PRELOAD="$ASAN_LIB"
# fi
# "$@"
# ----------------------------------------------------------------
HERE="$(cd "$(dirname "$0")" && pwd)"
export ASAN_OPTIONS=log_to_syslog=false,allow_user_segv_handler=1

# 设置库搜索路径，包含应用的原生库目录
export LD_LIBRARY_PATH="$HERE:$LD_LIBRARY_PATH"

# 加载 ASan 运行时库
ASAN_LIB=$(ls $HERE/libclang_rt.asan-*-android.so)
echo "ASan wrap.sh: Loading libraries ASAN_LIB=${ASAN_LIB}...HERE=${HERE}" 

if [ -f "$HERE/libc++_shared.so" ]; then
    export LD_PRELOAD="$ASAN_LIB $HERE/libc++_shared.so"
else
    export LD_PRELOAD="$ASAN_LIB"
fi

# 添加调试信息（可选）
echo "ASan wrap.sh: Loading libraries from $HERE" > /data/local/tmp/asan_debug.log

exec "$@"