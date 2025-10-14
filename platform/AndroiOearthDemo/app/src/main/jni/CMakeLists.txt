# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html.
# For more examples on how to use CMake, see https://github.com/android/ndk-samples.

# Sets the minimum CMake version required for this project.
cmake_minimum_required(VERSION 3.22.1)

# Declares the project name. The project name can be accessed via ${ PROJECT_NAME},
# Since this is the top level CMakeLists.txt, the project name is also accessible
# with ${CMAKE_PROJECT_NAME} (both CMake variables are in-sync within the top level
# build script scope).
project("androiOearthDemo01")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)


# 对所有共享库启用 16KB 对齐
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,max-page-size=16384")


# -------- CMAKE_ANDROID_ARCH_ABI
# set(CMAKE_ANDROID_ARCH_ABI  "x86_64" CACHE STRING 
#         "Value should only be one of arm64-v8a, x86_64, armeabi-v7a or x86")
set(ANDROID_API_NAME ${CMAKE_ANDROID_ARCH_ABI})
if( ANDROID_API_NAME  MATCHES "arm64-v8a|x86_64|armeabi-v7a|x86")
    message(STATUS "ANDROID_API_NAME=${ANDROID_API_NAME} is ok!")    
else()
    message(FATAL_ERROR "ANDROID_API_NAME=${ANDROID_API_NAME} **NOT** MATCHES arm64-v8a|x86_64|armeabi-v7a|x86 !")    
endif()

# ------Libs3rd 
set(Libs3rd_RootDIR "" CACHE PATH "Location of 3rd libraries folder")
mark_as_advanced(Libs3rd_RootDIR)
if(NOT Libs3rd_RootDIR OR NOT EXISTS "${Libs3rd_RootDIR}")
    message(FATAL_ERROR "Libs3rd_RootDIR=${Libs3rd_RootDIR} NOT EXISTS !")
else ()
    message(STATUS "Libs3rd_RootDIR=${Libs3rd_RootDIR} EXISTS ^-^!")
endif()
 

set(Libs3rd_includeDIRS "")
set(Libs3rd_LIBS "")
if( NOT EXISTS "${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "Libs3rd_RootDIR=${Libs3rd_RootDIR} NOT EXISTS !")
else()
    list(APPEND    Libs3rd_includeDIRS
       ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/include 
        )       
    list(APPEND  Libs3rd_LIBS 
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/libosgEarth.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_earth.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_gltf.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_kml.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_bumpmap.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_cache_filesystem.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_colorramp.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_detail.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_engine_rex.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_featurefilter_intersect.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_featurefilter_join.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_scriptengine_javascript.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_sky_gl.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_sky_simple.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_terrainshader.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_vdatum_egm2008.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_vdatum_egm84.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_vdatum_egm96.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_osgearth_viewpoints.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_template.a
        ${Libs3rd_RootDIR}/osgearth/${ANDROID_API_NAME}/lib/osgdb_zip.a        
     )    
        
endif()


if( NOT EXISTS "${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "Libs3rd_RootDIR=${Libs3rd_RootDIR} NOT EXISTS !")
else()
    list(APPEND    Libs3rd_includeDIRS
       ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/include 
        )        

    list(APPEND  Libs3rd_LIBS 
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libOpenThreads.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosg.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgAnimation.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgDB.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgFX.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgGA.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgManipulator.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgParticle.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgPresentation.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgShadow.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgSim.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgTerrain.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgText.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgUI.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgUtil.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgViewer.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgVolume.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/libosgWidget.a        
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_3dc.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_ac.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_bmp.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_bsp.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_bvh.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_cfg.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_curl.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_dds.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_deprecated_osg.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_deprecated_osganimation.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgfx.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgparticle.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgshadow.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgsim.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgterrain.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgtext.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgviewer.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgvolume.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgwidget.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_dot.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_dxf.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_freetype.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_gdal.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_gles.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_glsl.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_gz.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_hdr.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_ive.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_jpeg.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_ktx.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_logo.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_lua.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_lws.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_md2.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_mdl.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_normals.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_obj.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_ogr.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_openflight.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_osc.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_osg.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_osga.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_osgjs.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_osgshadow.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_osgterrain.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_osgtgz.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_osgviewer.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_p3d.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_pic.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_png.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_pnm.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_pov.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_pvr.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_revisions.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_rgb.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_rot.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_scale.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osg.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osganimation.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osgfx.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osgga.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osgmanipulator.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osgparticle.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osgshadow.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osgsim.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osgterrain.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osgtext.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osgui.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osgutil.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osgviewer.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_serializers_osgvolume.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_shp.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_stl.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_tf.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_tga.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_tgz.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_tiff.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_trans.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_trk.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_txf.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_vtf.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_x.a
        ${Libs3rd_RootDIR}/osg/${ANDROID_API_NAME}/lib/osgPlugins-3.7.0/libosgdb_zip.a        
    )
  
endif()


if( NOT EXISTS "${Libs3rd_RootDIR}/libjpeg-turbo/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "libjpeg--include=${Libs3rd_RootDIR}/libjpeg-turbo/${ANDROID_API_NAME}/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${Libs3rd_RootDIR}/libjpeg-turbo/${ANDROID_API_NAME}/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${Libs3rd_RootDIR}/libjpeg-turbo/${ANDROID_API_NAME}/lib/libjpeg.a
    )
endif()


if( NOT EXISTS "${Libs3rd_RootDIR}/libpng/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "libpng--include=${Libs3rd_RootDIR}/libpng/${ANDROID_API_NAME}/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${Libs3rd_RootDIR}/libpng/${ANDROID_API_NAME}/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${Libs3rd_RootDIR}/libpng/${ANDROID_API_NAME}/lib/libpng.a
    )
endif()


if( NOT EXISTS "${Libs3rd_RootDIR}/libtiff/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "libtiff--include=${Libs3rd_RootDIR}/libtiff/${ANDROID_API_NAME}/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${Libs3rd_RootDIR}/libtiff/${ANDROID_API_NAME}/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${Libs3rd_RootDIR}/libtiff/${ANDROID_API_NAME}/lib/libtiff.a
    )
endif()


if( NOT EXISTS "${Libs3rd_RootDIR}/curl/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "curl--include=${Libs3rd_RootDIR}/curl/${ANDROID_API_NAME}/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${Libs3rd_RootDIR}/curl/${ANDROID_API_NAME}/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${Libs3rd_RootDIR}/curl/${ANDROID_API_NAME}/lib/libcurl-d.a
    )
endif()


if( NOT EXISTS "${Libs3rd_RootDIR}/freetype/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "freetype--include=${Libs3rd_RootDIR}/freetype/${ANDROID_API_NAME}/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${Libs3rd_RootDIR}/freetype/${ANDROID_API_NAME}/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${Libs3rd_RootDIR}/freetype/${ANDROID_API_NAME}/lib/libfreetyped.a
    )
endif()


if( NOT EXISTS "${Libs3rd_RootDIR}/gdal/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "gdal--include=${Libs3rd_RootDIR}/gdal/${ANDROID_API_NAME}/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${Libs3rd_RootDIR}/gdal/${ANDROID_API_NAME}/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${Libs3rd_RootDIR}/gdal/${ANDROID_API_NAME}/lib/libgdal.a
    )
endif()


if( NOT EXISTS "${Libs3rd_RootDIR}/geos/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "geos--include=${Libs3rd_RootDIR}/geos/${ANDROID_API_NAME}/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${Libs3rd_RootDIR}/geos/${ANDROID_API_NAME}/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${Libs3rd_RootDIR}/geos/${ANDROID_API_NAME}/lib/libgeos_c.a
        ${Libs3rd_RootDIR}/geos/${ANDROID_API_NAME}/lib/libgeos.a
    )
endif()


if( NOT EXISTS "${Libs3rd_RootDIR}/openssl/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "openssl--include=${Libs3rd_RootDIR}/openssl/${ANDROID_API_NAME}/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${Libs3rd_RootDIR}/openssl/${ANDROID_API_NAME}/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${Libs3rd_RootDIR}/openssl/${ANDROID_API_NAME}/lib/libssl.a
        ${Libs3rd_RootDIR}/openssl/${ANDROID_API_NAME}/lib/libcrypto.a
    )
endif()



if( NOT EXISTS "${Libs3rd_RootDIR}/proj/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "proj--include=${Libs3rd_RootDIR}/proj/${ANDROID_API_NAME}/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${Libs3rd_RootDIR}/proj/${ANDROID_API_NAME}/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${Libs3rd_RootDIR}/proj/${ANDROID_API_NAME}/lib/libproj.a 
    )
endif()


if( NOT EXISTS "${Libs3rd_RootDIR}/protobuf/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "protobuf--include=${Libs3rd_RootDIR}/protobuf/${ANDROID_API_NAME}/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${Libs3rd_RootDIR}/protobuf/${ANDROID_API_NAME}/include
    #     )        
    list(APPEND  Libs3rd_LIBS  
        ${Libs3rd_RootDIR}/protobuf/${ANDROID_API_NAME}/lib/libprotobuf-lited.a  
        ${Libs3rd_RootDIR}/protobuf/${ANDROID_API_NAME}/lib/libprotobufd.a  
        ${Libs3rd_RootDIR}/protobuf/${ANDROID_API_NAME}/lib/libupbd.a  
        ${Libs3rd_RootDIR}/protobuf/${ANDROID_API_NAME}/lib/libutf8_range.a  
        ${Libs3rd_RootDIR}/protobuf/${ANDROID_API_NAME}/lib/libutf8_validity.a
    )
endif()
 

if( NOT EXISTS "${Libs3rd_RootDIR}/sqlite/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "sqlite--include=${Libs3rd_RootDIR}/sqlite/${ANDROID_API_NAME}/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${Libs3rd_RootDIR}/sqlite/${ANDROID_API_NAME}/include
    #     )        
    list(APPEND  Libs3rd_LIBS   
        ${Libs3rd_RootDIR}/sqlite/${ANDROID_API_NAME}/lib/libsqlite3.a   
    )
endif()

if( NOT EXISTS "${Libs3rd_RootDIR}/zlib/${ANDROID_API_NAME}/include")
    message(FATAL_ERROR "zlib--include=${Libs3rd_RootDIR}/zlib/${ANDROID_API_NAME}/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${Libs3rd_RootDIR}/zlib/${ANDROID_API_NAME}/include
    #     )        
    list(APPEND  Libs3rd_LIBS   
        ${Libs3rd_RootDIR}/zlib/${ANDROID_API_NAME}/lib/libz.a   
    )
endif()

# ------OEarthJni_SRC_FILES 
# Creates and names a library, sets it as either STATIC
# or SHARED, and provides the relative paths to its source code.
# You can define multiple libraries, and CMake builds them for you.
# Gradle automatically packages shared libraries with your APK.
#
# In this top level CMakeLists.txt, ${CMAKE_PROJECT_NAME} is used to define
# the target library name; in the sub-module's CMakeLists.txt, ${PROJECT_NAME}
# is preferred for the same purpose.
#
# In order to load a library into your app from Java/Kotlin, you must call
# System.loadLibrary() and pass the name of the library defined here;
# for GameActivity/NativeActivity derived applications, the same library name must be
# used in the AndroidManifest.xml file.
set(OEarthJni_SRC_FILES 
        osgNativeLib.cpp 
        OsgMainApp.cpp 
        OsgAndroidNotifyHandler.cpp)

message(STATUS "Libs3rd_includeDIRS=${Libs3rd_includeDIRS} haha!")
message(STATUS "Libs3rd_LIBS=${Libs3rd_LIBS} haha!")

# return() #### hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh

add_library(${CMAKE_PROJECT_NAME} SHARED
        # List C/C++ source files with relative paths to this CMakeLists.txt.
        ${OEarthJni_SRC_FILES} )

target_compile_definitions(${CMAKE_PROJECT_NAME}
    PRIVATE
        -DOSG_LIBRARY_STATIC=1, 
        -DOSGEARTH_LIBRARY_STATIC=1
        )

target_include_directories(${CMAKE_PROJECT_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        ${Libs3rd_includeDIRS}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/
)

# Specifies libraries CMake should link to your target library. You
# can link libraries from various origins, such as libraries defined in this
# build script, prebuilt third-party libraries, or Android system libraries.
target_link_libraries(${CMAKE_PROJECT_NAME}
        # List libraries link to the target library
        ${Libs3rd_LIBS}
        android
        log
        GLESv3  
        # ​​NDK r18+（推荐）​​：Google 移除了 gnustl（GNU STL），仅保留 libc++（LLVM 的 C++ 标准库）。​
        #                  ​无需再链接 gnustl_static或 supc++​​。
        #                  自动链接 libc++，无需手动指定
        # ​​NDK r17 及更早​​：若使用 GNU STL，需显式链接 gnustl_static和 supc++。
        dl         
        )