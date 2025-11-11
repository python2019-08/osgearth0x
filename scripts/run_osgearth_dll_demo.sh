#!/bin/bash
startTm=$(date +%Y/%m/%d--%H:%M:%S) 
echo "run_osgearth_dll_demo.sh ${startTm}: param 0=$0"

# ---- paths 
InstallROOT_ubuntu=/home/abner/abner2/zdev/nv/osgearth0x/build_by_sh/install/ubuntu/

InstallDIR_3rd=${InstallROOT_ubuntu}/3rd 
InstallDIR_osgearthdll=${InstallDIR_3rd}/osgearthdll 
InstallDIR_osgdll=${InstallDIR_3rd}/osgdll 

# ---- LD_LIBRARY_PATH
LD_LIBRARY_PATH=${InstallDIR_osgdll}/lib:${LD_LIBRARY_PATH}
LD_LIBRARY_PATH=${InstallDIR_osgdll}/lib/osgPlugins-3.7.0:${LD_LIBRARY_PATH}
LD_LIBRARY_PATH=${InstallDIR_osgearthdll}/lib:${LD_LIBRARY_PATH}
LD_LIBRARY_PATH=${InstallDIR_osgearthdll}/lib/osgPlugins-3.7.0:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH
# ---- DYLD_LIBRARY_PATH
DYLD_LIBRARY_PATH=${InstallDIR_osgdll}/lib:${DYLD_LIBRARY_PATH}
DYLD_LIBRARY_PATH=${InstallDIR_osgdll}/lib/osgPlugins-3.7.0:${DYLD_LIBRARY_PATH}
DYLD_LIBRARY_PATH=${InstallDIR_osgearthdll}/lib:${DYLD_LIBRARY_PATH}
DYLD_LIBRARY_PATH=${InstallDIR_osgearthdll}/lib/osgPlugins-3.7.0:${DYLD_LIBRARY_PATH}
export DYLD_LIBRARY_PATH

# ---- run exe
ROOT_osgearth_src=/home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/
${InstallDIR_osgearthdll}/bin/osgearth_skyview  ${ROOT_osgearth_src}/tests/skyview2.earth

