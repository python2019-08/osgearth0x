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

