# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html.
# For more examples on how to use CMake, see https://github.com/android/ndk-samples.

# Sets the minimum CMake version required for this project.
cmake_minimum_required(VERSION 3.22.1)

# Declares the project name. The project name can be accessed via ${ PROJECT_NAME},
# Since this is the top level CMakeLists.txt, the project name is also accessible
# with ${CMAKE_PROJECT_NAME} (both CMake variables are in-sync within the top level
# build script scope).
project("Lnx8SkyDemo")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# include(GNUInstallDirs)
# set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
# set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
# set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR})


if(CMAKE_CROSSCOMPILING)
  message(STATUS "Cross-compiling: "
    "${CMAKE_HOST_SYSTEM_NAME}/${CMAKE_HOST_SYSTEM_PROCESSOR} -> "
    "${CMAKE_SYSTEM_NAME}/${CMAKE_SYSTEM_PROCESSOR}")
else()
  message(STATUS "**NOT** Cross-compiling: "
    "${CMAKE_HOST_SYSTEM_NAME}/${CMAKE_HOST_SYSTEM_PROCESSOR} -> "
    "${CMAKE_SYSTEM_NAME}/${CMAKE_SYSTEM_PROCESSOR}")    
endif()

# message(FATAL_ERROR "----------only for debug-------------- !")
# return() ##only for debug-

# 对所有共享库启用 16KB 对齐
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,max-page-size=16384")
 
find_package(OpenGL)
if( (NOT DEFINED OPENGL_FOUND) OR (NOT OPENGL_FOUND)  )
  message(STATUS "OPENGL EXISTS ^-^!!OPENGL_INCLUDE_DIR=${OPENGL_INCLUDE_DIR}!!OPENGL_LIBRARIES=${OPENGL_LIBRARIES}")
endif()



# ------Libs3rd 
set(InstallRoot_3rd "" CACHE PATH "Location of 3rd libraries folder")
mark_as_advanced(InstallRoot_3rd)
if( (NOT InstallRoot_3rd) OR (NOT EXISTS "${InstallRoot_3rd}")  )
    message(FATAL_ERROR "InstallRoot_3rd=${InstallRoot_3rd} NOT EXISTS !")
else ()
    message(STATUS "InstallRoot_3rd=${InstallRoot_3rd} EXISTS ^-^!")
endif()
 

set(Libs3rd_includeDIRS "")
set(Libs3rd_LIBS "")
if( NOT EXISTS "${InstallRoot_3rd}/osgearth/include")
    message(FATAL_ERROR "InstallRoot_3rd=${InstallRoot_3rd} NOT EXISTS !")
else()
    list(APPEND    Libs3rd_includeDIRS
       ${InstallRoot_3rd}/osgearth/include 
        )       
    list(APPEND  Libs3rd_LIBS      
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_bumpmap.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_cache_filesystem.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_colorramp.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_detail.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_engine_rex.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_featurefilter_intersect.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_featurefilter_join.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_scriptengine_javascript.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_sky_gl.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_sky_simple.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_terrainshader.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_vdatum_egm2008.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_vdatum_egm84.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_vdatum_egm96.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_osgearth_viewpoints.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_template.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_zip.a   
        ${InstallRoot_3rd}/osgearth/lib/osgdb_gltf.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_kml.a
        ${InstallRoot_3rd}/osgearth/lib/osgdb_earth.a
        ${InstallRoot_3rd}/osgearth/lib/libosgEarth.a             
     )    
        
endif()


if( NOT EXISTS "${InstallRoot_3rd}/osg/include")
    message(FATAL_ERROR "InstallRoot_3rd=${InstallRoot_3rd} NOT EXISTS !")
else()
    list(APPEND    Libs3rd_includeDIRS
       ${InstallRoot_3rd}/osg/include 
        )        

    list(APPEND  Libs3rd_LIBS    
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_3dc.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_ac.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_bmp.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_bsp.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_bvh.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_cfg.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_curl.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_dds.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_deprecated_osg.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_deprecated_osganimation.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgfx.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgparticle.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgshadow.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgsim.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgterrain.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgtext.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgviewer.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgvolume.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_deprecated_osgwidget.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_dot.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_dxf.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_freetype.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_gdal.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_gles.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_glsl.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_gz.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_hdr.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_ive.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_jpeg.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_ktx.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_logo.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_lua.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_lws.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_md2.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_mdl.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_normals.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_obj.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_ogr.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_openflight.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_osc.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_osg.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_osga.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_osgjs.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_osgshadow.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_osgterrain.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_osgtgz.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_osgviewer.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_p3d.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_pic.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_png.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_pnm.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_pov.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_pvr.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_revisions.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_rgb.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_rot.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_scale.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osg.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osganimation.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osgfx.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osgga.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osgmanipulator.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osgparticle.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osgshadow.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osgsim.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osgterrain.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osgtext.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osgui.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osgutil.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osgviewer.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_serializers_osgvolume.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_shp.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_stl.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_tf.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_tga.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_tgz.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_tiff.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_trans.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_trk.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_txf.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_vtf.a
        ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_x.a
        # -------------------------------------------
        # ### do not use "osg/**/libosgdb_zip.a", but use "osgearth/**/osgdb_zip.a". 
        # ${InstallRoot_3rd}/osg/lib/osgPlugins-3.7.0/libosgdb_zip.a   
        # -------------------------------------------             
        ${InstallRoot_3rd}/osg/lib/libosgPresentation.a              
        ${InstallRoot_3rd}/osg/lib/libosgUI.a        
        ${InstallRoot_3rd}/osg/lib/libosgWidget.a 
        ${InstallRoot_3rd}/osg/lib/libosgViewer.a    
        ${InstallRoot_3rd}/osg/lib/libosgVolume.a
        ${InstallRoot_3rd}/osg/lib/libosgTerrain.a
        ${InstallRoot_3rd}/osg/lib/libosgText.a
        ${InstallRoot_3rd}/osg/lib/libosgShadow.a
        ${InstallRoot_3rd}/osg/lib/libosgSim.a
        ${InstallRoot_3rd}/osg/lib/libosgParticle.a
        ${InstallRoot_3rd}/osg/lib/libosgManipulator.a
        ${InstallRoot_3rd}/osg/lib/libosgGA.a
        ${InstallRoot_3rd}/osg/lib/libosgFX.a 
        ${InstallRoot_3rd}/osg/lib/libosgDB.a
        ${InstallRoot_3rd}/osg/lib/libosgAnimation.a 
        ${InstallRoot_3rd}/osg/lib/libosgUtil.a 
        ${InstallRoot_3rd}/osg/lib/libosg.a 
        ${InstallRoot_3rd}/osg/lib/libOpenThreads.a            
    )
  
endif()

if( NOT EXISTS "${InstallRoot_3rd}/gdal/include")
    message(FATAL_ERROR "gdal--include=${InstallRoot_3rd}/gdal/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/gdal/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${InstallRoot_3rd}/gdal/lib/libgdal.a
    )
endif()



if( NOT EXISTS "${InstallRoot_3rd}/curl/include")
    message(FATAL_ERROR "curl--include=${InstallRoot_3rd}/curl/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/curl/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${InstallRoot_3rd}/curl/lib/libcurl-d.a
    )
endif()


if( NOT EXISTS "${InstallRoot_3rd}/freetype/include")
    message(FATAL_ERROR "freetype--include=${InstallRoot_3rd}/freetype/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/freetype/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${InstallRoot_3rd}/freetype/lib/libfreetyped.a
    )
endif()

if( NOT EXISTS "${InstallRoot_3rd}/libtiff/include")
    message(FATAL_ERROR "libtiff--include=${InstallRoot_3rd}/libtiff/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/libtiff/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${InstallRoot_3rd}/libtiff/lib/libtiff.a
    )
endif()

if( NOT EXISTS "${InstallRoot_3rd}/libjpeg-turbo/include")
    message(FATAL_ERROR "libjpeg--include=${InstallRoot_3rd}/libjpeg-turbo/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/libjpeg-turbo/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${InstallRoot_3rd}/libjpeg-turbo/lib/libjpeg.a
    )
endif()


if( NOT EXISTS "${InstallRoot_3rd}/libpng/include")
    message(FATAL_ERROR "libpng--include=${InstallRoot_3rd}/libpng/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/libpng/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${InstallRoot_3rd}/libpng/lib/libpng.a
    )
endif()



if( NOT EXISTS "${InstallRoot_3rd}/proj/include")
    message(FATAL_ERROR "proj--include=${InstallRoot_3rd}/proj/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/proj/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${InstallRoot_3rd}/proj/lib/libproj.a 
    )
endif()

 

if( NOT EXISTS "${InstallRoot_3rd}/geos/include")
    message(FATAL_ERROR "geos--include=${InstallRoot_3rd}/geos/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/geos/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${InstallRoot_3rd}/geos/lib/libgeos_c.a
        ${InstallRoot_3rd}/geos/lib/libgeos.a
    )
endif()


if( NOT EXISTS "${InstallRoot_3rd}/openssl/include")
    message(FATAL_ERROR "openssl--include=${InstallRoot_3rd}/openssl/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/openssl/include
    #     )        
    list(APPEND  Libs3rd_LIBS 
        ${InstallRoot_3rd}/openssl/lib64/libssl.a
        ${InstallRoot_3rd}/openssl/lib64/libcrypto.a
    )
endif()



if( NOT EXISTS "${InstallRoot_3rd}/protobuf/include")
    message(FATAL_ERROR "protobuf--include=${InstallRoot_3rd}/protobuf/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/protobuf/include
    #     )        
    list(APPEND  Libs3rd_LIBS  
        ${InstallRoot_3rd}/protobuf/lib/libprotobuf-lited.a  
        ${InstallRoot_3rd}/protobuf/lib/libprotobufd.a  
        ${InstallRoot_3rd}/protobuf/lib/libupbd.a  
        ${InstallRoot_3rd}/protobuf/lib/libutf8_range.a  
        ${InstallRoot_3rd}/protobuf/lib/libutf8_validity.a
    )
endif()
 

if( NOT EXISTS "${InstallRoot_3rd}/sqlite/include")
    message(FATAL_ERROR "sqlite--include=${InstallRoot_3rd}/sqlite/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/sqlite/include
    #     )        
    list(APPEND  Libs3rd_LIBS   
        ${InstallRoot_3rd}/sqlite/lib/libsqlite3.a   
    )
endif()

if( NOT EXISTS "${InstallRoot_3rd}/zlib/include")
    message(FATAL_ERROR "zlib--include=${InstallRoot_3rd}/zlib/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/zlib/include
    #     )        
    list(APPEND  Libs3rd_LIBS   
        ${InstallRoot_3rd}/zlib/lib/libz.a   
    )
endif()

if( NOT EXISTS "${InstallRoot_3rd}/libzip/include")
    message(FATAL_ERROR "libzip--include=${InstallRoot_3rd}/libzip/include  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/zlib/include
    #     )        
    list(APPEND  Libs3rd_LIBS   
        ${InstallRoot_3rd}/libzip/lib/libzip.a   
    )
endif()

if( NOT EXISTS "${InstallRoot_3rd}/xz/lib")
    message(FATAL_ERROR "xz--include=${InstallRoot_3rd}/xz/lib  NOT EXISTS !")
else()
    # list(APPEND    Libs3rd_includeDIRS
    #     ${InstallRoot_3rd}/zlib/include
    #     )        
    list(APPEND  Libs3rd_LIBS   
        ${InstallRoot_3rd}/xz/lib/liblzma.a   
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
set(LNX8Sky_SRC_FILES 
        # a-native-lib.cpp  // a-native-lib.cpp is created by wizard
        demo_simple_sky.cpp   
        )

message(STATUS "haha...Libs3rd_includeDIRS=${Libs3rd_includeDIRS}")
message(STATUS "haha...Libs3rd_LIBS=${Libs3rd_LIBS}")

# return() #### hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh

add_executable(${CMAKE_PROJECT_NAME}  
        # List C/C++ source files with relative paths to this CMakeLists.txt.
        ${LNX8Sky_SRC_FILES} )

target_compile_definitions(${CMAKE_PROJECT_NAME}
    PRIVATE
        -DOSG_LIBRARY_STATIC=1, 
        -DOSGEARTH_LIBRARY_STATIC=1
        )

target_include_directories(${CMAKE_PROJECT_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        ${Libs3rd_includeDIRS}
        ${OPENGL_INCLUDE_DIR}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/
)

# Specifies libraries CMake should link to your target library. You
# can link libraries from various origins, such as libraries defined in this
# build script, prebuilt third-party libraries, or Android system libraries.
target_link_libraries(${CMAKE_PROJECT_NAME}
        # List libraries link to the target library
        ${Libs3rd_LIBS}
        ${OPENGL_LIBRARIES}  
        )