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
  # ld: malformed 64-bit a.b.c.d.e version number: 9.0.20210922
  echo "set(VTK_BUILD_VERSION 0)" >> VTK/CMake/vtkVersion.cmake

  mkdir build-native-vtk
  cd build-native-vtk
  CC=$CC_FOR_BUILD CXX=$CXX_FOR_BUILD CFLAGS= CXXFLAGS= CPPFLAGS= LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX} \
     cmake -LAH -DCMAKE_INSTALL_PREFIX=$SRC_DIR/vtk-compile-tools \
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
  
  mkdir build-native
  cd build-native
  CC=$CC_FOR_BUILD CXX=$CXX_FOR_BUILD CFLAGS= CXXFLAGS= CPPFLAGS= LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX} \
     cmake -LAH -DCMAKE_BUILD_TYPE=Release ..
  make ProcessXML -j${CPU_COUNT}
  cd ..
  echo "add_executable(ParaView::ProcessXML IMPORTED GLOBAL)" > Utilities/ProcessXML/CMakeLists.txt
  echo "set_property(TARGET ParaView::ProcessXML PROPERTY IMPORTED_LOCATION $PWD/build-native/bin/vtkProcessXML-pv${MAJ_MIN})" >> Utilities/ProcessXML/CMakeLists.txt
  echo "add_custom_target(ProcessXML)" >> Utilities/ProcessXML/CMakeLists.txt
  echo "add_dependencies(ProcessXML ParaView::ProcessXML)" >> Utilities/ProcessXML/CMakeLists.txt

  # disable plugins doc
  curl -L https://gitlab.kitware.com/paraview/paraview/-/merge_requests/5613.patch | patch -p1
  CMAKE_ARGS="${CMAKE_ARGS} -DPARAVIEW_PLUGIN_DISABLE_XML_DOCUMENTATION=ON"
fi

mkdir build && cd build

cmake -LAH \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_PREFIX_PATH=${PREFIX} \
  -DCMAKE_FIND_FRAMEWORK=LAST \
  -DCMAKE_INSTALL_RPATH:STRING=${PREFIX}/lib \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_BUILD_TYPE=Release \
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
