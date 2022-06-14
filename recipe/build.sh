#!/bin/sh

# https://gitlab.kitware.com/paraview/paraview/issues/19645
export LDFLAGS=`echo "${LDFLAGS}" | sed "s|-Wl,-dead_strip_dylibs||g"`

if [[ "$build_variant" == "egl" ]]; then
  CMAKE_ARGS="-DVTK_USE_X=OFF -DVTK_OPENGL_HAS_EGL=ON -DPARAVIEW_USE_QT=OFF -DVTK_MODULE_USE_EXTERNAL_VTK_glew=OFF"
  CMAKE_ARGS="${CMAKE_ARGS} -DEGL_INCLUDE_DIR=${BUILD_PREFIX}/${HOST}/sysroot/usr/include"
  CMAKE_ARGS="${CMAKE_ARGS} -DEGL_LIBRARY=${BUILD_PREFIX}/${HOST}/sysroot/usr/lib/libEGL.so.1"
  CMAKE_ARGS="${CMAKE_ARGS} -DEGL_opengl_LIBRARY=${BUILD_PREFIX}/${HOST}/sysroot/usr/lib64/libGL.so"
  CMAKE_ARGS="${CMAKE_ARGS} -DOPENGL_opengl_LIBRARY=${BUILD_PREFIX}/${HOST}/sysroot/usr/lib64/libGL.so"
elif [[ "$build_variant" == "qt" ]]; then
  CMAKE_ARGS=""
fi

if test "${CONDA_BUILD_CROSS_COMPILATION}" == "1"
then
  mkdir build-native
  cd build-native
  export CC=$CC_FOR_BUILD
  export CXX=$CXX_FOR_BUILD
  unset CFLAGS
  unset CXXFLAGS
  unset CPPFLAGS
  export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
  unset LD
  cmake -DCMAKE_INSTALL_PREFIX=$SRC_DIR/vtk-compile-tools \
     -DCMAKE_PREFIX_PATH=$BUILD_PREFIX \
     -DCMAKE_INSTALL_LIBDIR=lib \
     -DCMAKE_BUILD_TYPE=Release \
     -DVTK_BUILD_COMPILE_TOOLS_ONLY=ON ../VTK
  make install -j${CPU_COUNT} VERBOSE=1
  cd ..
  MAJ_MIN=$(echo $PKG_VERSION | rev | cut -d"." -f2- | rev)
  CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc"
  CMAKE_ARGS="${CMAKE_ARGS} -DVTKCompileTools_DIR=$SRC_DIR/vtk-compile-tools/lib/cmake/vtkcompiletools-${MAJ_MIN}/"
  CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_REQUIRE_LARGE_FILE_SUPPORT=1 -DCMAKE_REQUIRE_LARGE_FILE_SUPPORT__TRYRUN_OUTPUT="
  CMAKE_ARGS="${CMAKE_ARGS} -DVTK_REQUIRE_LARGE_FILE_SUPPORT_EXITCODE=0 -DVTK_REQUIRE_LARGE_FILE_SUPPORT_EXITCODE__TRYRUN_OUTPUT="
  CMAKE_ARGS="${CMAKE_ARGS} -DXDMF_REQUIRE_LARGE_FILE_SUPPORT_EXITCODE=0 -DXDMF_REQUIRE_LARGE_FILE_SUPPORT_EXITCODE__TRYRUN_OUTPUT="
fi

mkdir build && cd build

cmake -LAH \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_PREFIX_PATH=${PREFIX} \
  -DCMAKE_FIND_FRAMEWORK=LAST \
  -DCMAKE_INSTALL_RPATH:STRING=${PREFIX}/lib \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_BUILD_TYPE=Release \
  -DPARAVIEW_INSTALL_DEVELOPMENT_FILES=ON \
  -DPARAVIEW_USE_VTKM=OFF \
  -DPARAVIEW_USE_PYTHON=ON \
  -DPython3_FIND_STRATEGY=LOCATION \
  -DPython3_ROOT_DIR=${PREFIX} \
  -DPARAVIEW_BUILD_WITH_EXTERNAL=ON \
  -DVTK_MODULE_USE_EXTERNAL_VTK_libharu=OFF \
  -DVTK_MODULE_USE_EXTERNAL_VTK_utf8=OFF \
  -DVTK_MODULE_USE_EXTERNAL_VTK_exprtk=OFF \
  -DVTK_MODULE_USE_EXTERNAL_VTK_fmt=OFF \
  -DVTK_MODULE_USE_EXTERNAL_VTK_cli11=OFF \
  -DVTK_MODULE_USE_EXTERNAL_VTK_ioss=OFF \
  -DVTK_MODULE_USE_EXTERNAL_ParaView_vtkcatalyst=OFF \
  -DPARAVIEW_ENABLE_WEB=ON \
  -DPARAVIEW_ENABLE_VISITBRIDGE=ON \
  -DPARAVIEW_ENABLE_XDMF3=ON \
  ${CMAKE_ARGS} \
  ..
make install -j${CPU_COUNT}

if test `uname` = "Darwin"; then
  ln -s $PREFIX/Applications/paraview.app/Contents/MacOS/paraview ${PREFIX}/bin/paraview
fi
