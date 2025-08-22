
src:=. 

 
################################################################################
#
# Build ubuntu
#
LOCAL_CMAKE_SOURCE_DIR=$(PWD)
LOCAL_CMAKE_BINARY_DIR=$(PWD)/build/ubuntu

.PHONY: ubuntu clean

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

# ```shell
# #--- remark: my cmds 4 ubuntu-dbg-static
# git clone https://github.com/openscenegraph/OpenSceneGraph.git
# cd OpenSceneGraph

# # -DCMAKE_EXE_LINKER_FLAGS="-static" \

# cmake -S. -Bbuild/ubuntu-dbg-a \
#      -DOPENGL_PROFILE=GL3 \
#      -DOSG_GL_CONTEXT_VERSION=4.6  \
#      -DCMAKE_BUILD_TYPE=Debug  \
#         -DBUILD_SHARED_LIBS=OFF \
#         -DCMAKE_FIND_LIBRARY_SUFFIXES=.a \
#      -DDYNAMIC_OPENSCENEGRAPH=OFF \
#      -DDYNAMIC_OPENTHREADS=OFF



# ## build/ubuntu  && make -j8 
# cmake --build build/ubuntu-dbg-a -- VERBOSE=1 -j15 install 
# ```	