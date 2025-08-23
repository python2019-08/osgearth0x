#!/bin/bash

# -------------------------------------------------
# test
# -------------------------------------------------
isTest1=true
isTest2=true

if [ "${isTest1}" != "true" ] && \
   [ "${isTest2}" = "true"  ] ; then 
    echo "========== building test 1========== " &&  sleep 1
fi

exit 11 

if [ "${isTest1}" != "true" ] && [ "${isTest2}" = "true"  ] ; then 
     echo "========== building test 2========== " &&  sleep 1
fi

