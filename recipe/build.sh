#!/bin/sh

export LDFLAGS="$LDFLAGS -Wl,-rpath-link,$PREFIX/lib"

# do not build plugins
rm -r ./Plugins/*

mkdir build && cd build

cmake \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_PREFIX_PATH=${PREFIX} \
  -DCMAKE_INSTALL_RPATH:STRING=${PREFIX}/lib \
  -DVTK_INSTALL_LIBRARY_DIR="lib" \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTING:BOOL=OFF \
  -DBUILD_DOCUMENTATION:BOOL=OFF \
  -DBUILD_EXAMPLES:BOOL=OFF \
  -DPARAVIEW_BUILD_QT_GUI:BOOL=OFF \
  -DPARAVIEW_INSTALL_DEVELOPMENT_FILES:BOOL=ON \
  -DPARAVIEW_ENABLE_CATALYST:BOOL=OFF \
  -DPARAVIEW_ENABLE_PYTHON:BOOL=ON \
  -DPYTHON_EXECUTABLE=${PYTHON} \
  -DVTK_INSTALL_PYTHON_MODULE_DIR=${SP_DIR} \
  -DPARAVIEW_ENABLE_WEB:BOOL=ON \
  -DVTK_USE_X:BOOL=OFF \
  -DVTK_DEFAULT_RENDER_WINDOW_OFFSCREEN:BOOL=ON \
  -DVTK_USE_SYSTEM_LIBRARIES:BOOL=ON \
  -DVTK_USE_SYSTEM_PUGIXML:BOOL=OFF \
  -DVTK_USE_SYSTEM_AUTOBAHN:BOOL=OFF \
  -DVTK_USE_SYSTEM_GL2PS:BOOL=OFF \
  -DVTK_USE_SYSTEM_LIBHARU:BOOL=OFF \
  -DVTK_USE_SYSTEM_NETCDFCPP:BOOL=OFF \
  -DVTK_USE_SYSTEM_XDMF2=OFF \
  -DVTK_USE_SYSTEM_CGNS=OFF \
  -DVTK_USE_SYSTEM_JSONCPP=OFF \
  -DVTK_USE_SYSTEM_SIX=ON \
  -DVTK_USE_SYSTEM_ZOPE=ON \
  -DVTK_USE_SYSTEM_CONSTANTLY=ON \
  -DVTK_USE_SYSTEM_AUTOBAHN=ON \
  -DVTK_OPENGL_HAS_OSMESA:BOOL=ON \
  -DOSMESA_LIBRARY=${PREFIX}/lib/libOSMesa32.so \
  ..
make -j${CPU_COUNT}

# log hits limit
make install > /dev/null

# move paraview from lib/site-packages/ to SP_DIR
rm -r ${SP_DIR}/paraview
mv ${PREFIX}/lib/site-packages/paraview ${SP_DIR}

# use vtk from SP_DIR as vtk submodule
rm -rf ${SP_DIR}/paraview/vtk
cp -r ${SP_DIR}/vtk ${SP_DIR}/paraview
