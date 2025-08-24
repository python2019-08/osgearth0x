#!/bin/bash

# -------------------------------------------------
# test01
# -------------------------------------------------
isTest1=true
isTest2=true
vSameName="docs/test01"
if [ "${isTest1}" != "true" ] && \
   [ "${isTest2}" = "true"  ] ; then 
    echo "==== in docs/test01.sh: 1" &&  sleep 1
fi

 

if [ "${isTest1}" != "true" ] && [ "${isTest2}" = "true"  ] ; then 
     echo "========== in docs/test01.sh: 2" &&  sleep 1
fi

# ---------------------------------------
INSTALL_PREFIX_zlib=hh/zlib
INSTALL_PREFIX_xz=hh/xz
INSTALL_PREFIX_jpegTurbo=hh/jpegTurbo
INSTALL_PREFIX_openssl=hh/openssl
INSTALL_PREFIX_curl==hh/curl
INSTALL_PREFIX_sqlite==hh/sqlite

# 初始化空变量
cmk_prefixPath=""
# 遍历所有依赖路径变量
for path in \
  "${INSTALL_PREFIX_zlib}" \
  "${INSTALL_PREFIX_xz}" \
  "${INSTALL_PREFIX_jpegTurbo}" \
  "${INSTALL_PREFIX_openssl}" \
  "${INSTALL_PREFIX_curl}" \
  "${INSTALL_PREFIX_sqlite}"; do
  # 只拼接非空路径，避免空值导致的多余冒号
  if [ -n "$path" ]; then
    # 若已有内容，先加冒号分隔，再拼接新路径
    # ${cmk_prefixPath:+:} 表示：若 cmk_prefixPath 非空，则添加 :，避免开头或结尾出现多余冒号。
    cmk_prefixPath="${cmk_prefixPath}${cmk_prefixPath:+:}${path}"
  fi
done

echo "========== in docs/test01.sh: cmk_prefixPath=${cmk_prefixPath}" &&  sleep 1

# ====================================================
lib_dir=$(pwd)
lib64_dir=$(dirname ${lib_dir})
_LINKER_FLAGS="-L${lib_dir} -lcurl -ltiff -ljpeg -lsqlite3 -lprotobuf -lpng -llzma -lz"
_LINKER_FLAGS="${_LINKER_FLAGS} -L${lib64_dir} -lssl -lcrypto" \

echo "========== in docs/test01.sh: _LINKER_FLAGS=${_LINKER_FLAGS}"