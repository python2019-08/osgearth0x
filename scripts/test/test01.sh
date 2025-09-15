#!/bin/bash

# -------------------------------------------------
# test01
# -------------------------------------------------
isTest1=true
isTest2=false
vSameName="docs/test01"
if [ "${isTest1}" != "true" ] && \
   [ "${isTest2}" = "true"  ] ; then 
   
    echo "==== in docs/test01.sh: 1" &&  sleep 1
fi

# 
if true; then
     val01="jjjj"
fi
echo "==== in docs/test01.sh: $val01" 

# 
if [ "${isTest1}" != "true" ] && [ "${isTest2}" = "true"  ] ; then 
     echo "========== in docs/test01.sh: 2" &&  sleep 1
fi
 
# ---------------------------------------
lib_dir=$(pwd)
lib64_dir=$(dirname ${lib_dir})
_LINKER_FLAGS="-L${lib_dir} -lcurl -ltiff -ljpeg -lsqlite3 -lprotobuf -lpng -llzma -lz"
_LINKER_FLAGS="${_LINKER_FLAGS} -L${lib64_dir} -lssl -lcrypto" \

echo "========== in docs/test01.sh: _LINKER_FLAGS=${_LINKER_FLAGS}"
