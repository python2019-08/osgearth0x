
src:=. 

 
################################################################################
#
# Build ubuntu
#
LOCAL_CMAKE_SOURCE_DIR=$(PWD)
LOCAL_CMAKE_BINARY_DIR=$(PWD)/build/ubuntu

.PHONY: ubuntu clean osg

ubuntu:ubuntu/build   ubuntu/install
clean: ubuntu/build/clean

ubuntu/build:ubuntu/build/configure ubuntu/build/do-build
ubuntu/build/configure:
	cmake -S$(src)  -Bbuild/ubuntu 
ubuntu/build/do-build: 
	cmake --build build/ubuntu -- -j$(job) $(target)

ubuntu/build/clean:
	rm -rf build/ubuntu

ubuntu/build/rebuild:ubuntu/build/clean ubuntu/build
ubuntu/install:
	cmake --build build/ubuntu -- -j$(job) install

# -----------------------------
#  make osg   >bosg.txt  2>&1
# -----------------------------
# #--- remark: my cmds 4 ubuntu-dbg-static
# git clone https://github.com/openscenegraph/OpenSceneGraph.git
# cd OpenSceneGraph 
osg:
	rm -fr build/ubuntu-osg
	cd src/osg
	cmake -Ssrc/osg -Bbuild/ubuntu-osg  -DOPENGL_PROFILE=GL3  \
			-DOSG_GL_CONTEXT_VERSION=4.6   -DCMAKE_BUILD_TYPE=Debug  \
			-DBUILD_SHARED_LIBS=OFF  -DDYNAMIC_OPENSCENEGRAPH=OFF -DDYNAMIC_OPENTHREADS=OFF
			-DCMAKE_FIND_LIBRARY_SUFFIXES=.a 	
			# # -DCMAKE_EXE_LINKER_FLAGS="-static"  
	# cd build/ubuntu-osg && make -j8 
	# cmake --build build/ubuntu-osg -- VERBOSE=1 -j15 install 
	cmake --build build/ubuntu-osg -- VERBOSE=1 -j15 
 	