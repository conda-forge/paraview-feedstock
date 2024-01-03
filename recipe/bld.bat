
:: remove -GL from CXXFLAGS
set "CXXFLAGS=-MD"

:: from Azure
set "Boost_ROOT="

mkdir build && cd build
cmake -LAH -G"Ninja" ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
    -DCMAKE_INSTALL_LIBDIR="Library/lib" ^
    -DCMAKE_INSTALL_BINDIR="Library/bin" ^
    -DCMAKE_INSTALL_INCLUDEDIR="Library/include" ^
    -DCMAKE_INSTALL_DATAROOTDIR="Library/share" ^
    -DCMAKE_INSTALL_PREFIX="%PREFIX%" ^
    -DCMAKE_CXX_STANDARD=17 ^
    -DVTK_IGNORE_CMAKE_CXX11_CHECKS=ON ^
    -DPARAVIEW_USE_VTKM=OFF ^
    -DPARAVIEW_USE_PYTHON=ON ^
    -DPython3_FIND_STRATEGY=LOCATION ^
    -DPython3_ROOT_DIR="%PREFIX%" ^
    -DPARAVIEW_PYTHON_SITE_PACKAGES_SUFFIX="Lib/site-packages" ^
    -DPARAVIEW_BUILD_WITH_EXTERNAL=ON ^
    -DLZMA_LIBRARY="%LIBRARY_PREFIX%/lib/liblzma.lib" ^
    -DVTK_MODULE_USE_EXTERNAL_VTK_exprtk=OFF ^
    -DVTK_MODULE_USE_EXTERNAL_VTK_utf8=OFF ^
    -DVTK_MODULE_USE_EXTERNAL_VTK_ioss=OFF ^
    -DVTK_MODULE_USE_EXTERNAL_VTK_cgns=OFF ^
    -DVTK_MODULE_USE_EXTERNAL_VTK_verdict=OFF ^
    -DPARAVIEW_ENABLE_ADIOS2=ON ^
    -DPARAVIEW_ENABLE_WEB=ON ^
    -DPARAVIEW_ENABLE_XDMF3=ON ^
    ..
if errorlevel 1 exit 1

cmake --build . --target install --config Release --parallel %CPU_COUNT%
if errorlevel 1 exit 1

curl https://www.paraview.org/files/%PKG_VERSION:~0,4%/ParaViewGettingStarted-%PKG_VERSION%.pdf --create-dirs -o %LIBRARY_PREFIX%\doc\GettingStarted.pdf
if errorlevel 1 exit 1
