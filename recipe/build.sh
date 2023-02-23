#!/bin/sh

# https://gitlab.kitware.com/paraview/paraview/issues/19645
export LDFLAGS=`echo "${LDFLAGS}" | sed "s|-Wl,-dead_strip_dylibs||g"`

if test "${build_variant}" == "egl"; then
  CMAKE_ARGS="${CMAKE_ARGS} -DVTK_USE_X=OFF -DVTK_OPENGL_HAS_EGL=ON -DPARAVIEW_USE_QT=OFF -DVTK_MODULE_USE_EXTERNAL_VTK_glew=OFF"
  CMAKE_ARGS="${CMAKE_ARGS} -DEGL_INCLUDE_DIR=${BUILD_PREFIX}/${HOST}/sysroot/usr/include"
  CMAKE_ARGS="${CMAKE_ARGS} -DEGL_LIBRARY=${BUILD_PREFIX}/${HOST}/sysroot/usr/lib/libEGL.so.1"
  CMAKE_ARGS="${CMAKE_ARGS} -DEGL_opengl_LIBRARY=${BUILD_PREFIX}/${HOST}/sysroot/usr/lib64/libGL.so"
  CMAKE_ARGS="${CMAKE_ARGS} -DOPENGL_opengl_LIBRARY=${BUILD_PREFIX}/${HOST}/sysroot/usr/lib64/libGL.so"
fi

if test "${CONDA_BUILD_CROSS_COMPILATION}" == "1"; then
  # use native build tools
  mkdir build-native
  cd build-native
  CC=$CC_FOR_BUILD CXX=$CXX_FOR_BUILD CFLAGS= CXXFLAGS= CPPFLAGS= LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX} \
     cmake -G "Ninja" -DCMAKE_PREFIX_PATH=$BUILD_PREFIX -DCMAKE_BUILD_TYPE=Release ..
  cmake --build . --target ProcessXML WrapClientServer WrapHierarchy WrapPython WrapPythonInit
  cd ..
  cat ${RECIPE_DIR}/LocalUserOptions.cmake.in | sed "s|@PARAVIEW_NATIVE_BUILD_DIR@|$PWD/build-native|g" > VTK/Wrapping/Tools/LocalUserOptions.cmake
  CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc"
  CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_REQUIRE_LARGE_FILE_SUPPORT=1 -DCMAKE_REQUIRE_LARGE_FILE_SUPPORT__TRYRUN_OUTPUT="
  CMAKE_ARGS="${CMAKE_ARGS} -DVTK_REQUIRE_LARGE_FILE_SUPPORT_EXITCODE=0 -DVTK_REQUIRE_LARGE_FILE_SUPPORT_EXITCODE__TRYRUN_OUTPUT="
  CMAKE_ARGS="${CMAKE_ARGS} -DXDMF_REQUIRE_LARGE_FILE_SUPPORT_EXITCODE=0 -DXDMF_REQUIRE_LARGE_FILE_SUPPORT_EXITCODE__TRYRUN_OUTPUT="

  # disable doc
  CMAKE_ARGS="${CMAKE_ARGS} -DPARAVIEW_ENABLE_EMBEDDED_DOCUMENTATION=OFF -DPARAVIEW_PLUGIN_DISABLE_XML_DOCUMENTATION=ON"
fi

mkdir build && cd build

cmake -LAH -G "Ninja" ${CMAKE_ARGS} \
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
  -DVTK_MODULE_USE_EXTERNAL_VTK_exprtk=OFF \
  -DVTK_MODULE_USE_EXTERNAL_VTK_utf8=OFF \
  -DVTK_MODULE_USE_EXTERNAL_VTK_ioss=OFF \
  -DVTK_MODULE_USE_EXTERNAL_VTK_verdict=OFF \
  -DPARAVIEW_ENABLE_WEB=ON \
  -DPARAVIEW_ENABLE_VISITBRIDGE=ON \
  -DPARAVIEW_ENABLE_XDMF3=ON \
  ..
cmake --build . --target install

if test `uname` = "Darwin"; then
  ln -s $PREFIX/Applications/paraview.app/Contents/MacOS/paraview ${PREFIX}/bin/paraview
fi

curl https://www.paraview.org/files/v${PKG_VERSION:0:4}/ParaViewGettingStarted-${PKG_VERSION}.pdf --create-dirs -o ${PREFIX}/share/paraview-${PKG_VERSION:0:4}/doc/GettingStarted.pdf
