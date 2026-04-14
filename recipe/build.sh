#!/bin/sh

# https://gitlab.kitware.com/paraview/paraview/issues/19645
export LDFLAGS=`echo "${LDFLAGS}" | sed "s|-Wl,-dead_strip_dylibs||g"`

# https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

if [ "$(uname)" == "Linux" ]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DOPENGL_egl_LIBRARY:FILEPATH=${PREFIX}/lib/libEGL.so.1"
  CMAKE_ARGS="${CMAKE_ARGS} -DEGL_opengl_LIBRARY:FILEPATH=${PREFIX}/lib/libGL.so.1"
  CMAKE_ARGS="${CMAKE_ARGS} -DOPENGL_opengl_LIBRARY:FILEPATH=${PREFIX}/lib/libGL.so.1"
fi

# https://gitlab.kitware.com/paraview/paraview/-/work_items/23235
CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_POLICY_DEFAULT_CMP0076=NEW"

cmake ${CMAKE_ARGS} -LAH -G "Ninja" \
  -DCMAKE_FIND_FRAMEWORK=LAST \
  -DCMAKE_INSTALL_RPATH:STRING=${PREFIX}/lib \
  -DPARAVIEW_USE_VISKORES=OFF \
  -DPARAVIEW_USE_PYTHON=ON \
  -DPARAVIEW_USE_FORTRAN=OFF \
  -DPython3_FIND_STRATEGY=LOCATION \
  -DPython3_ROOT_DIR=${PREFIX} \
  -DPARAVIEW_BUILD_WITH_EXTERNAL=ON \
  -DPARAVIEW_USE_EXTERNAL_VTK=ON \
  -DPARAVIEW_ENABLE_WEB=ON \
  -DPARAVIEW_ENABLE_VISITBRIDGE=ON \
  -DPARAVIEW_ENABLE_XDMF3=ON \
  -DPARAVIEW_ENABLE_EMBEDDED_DOCUMENTATION=OFF \
  -DPARAVIEW_PLUGIN_DISABLE_XML_DOCUMENTATION=ON \
  -DPARAVIEW_PLUGIN_ENABLE_ParFlow=ON \
  -B build .
cmake --build build --target install

if [ "$(uname)" = "Darwin" ]; then
  ln -s $PREFIX/Applications/paraview.app/Contents/MacOS/paraview ${PREFIX}/bin/paraview
fi

curl https://www.paraview.org/files/v${PKG_VERSION:0:4}/ParaViewGettingStarted-${PKG_VERSION}.pdf --create-dirs -o ${PREFIX}/share/paraview-${PKG_VERSION:0:4}/doc/GettingStarted.pdf
