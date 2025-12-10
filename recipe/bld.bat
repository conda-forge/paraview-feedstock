
:: remove -GL from CXXFLAGS
set "CXXFLAGS=-MD"

cmake %CMAKE_ARGS% -LAH -G"Ninja" ^
    -DCMAKE_INSTALL_LIBDIR="Library/lib" ^
    -DCMAKE_INSTALL_BINDIR="Library/bin" ^
    -DCMAKE_INSTALL_INCLUDEDIR="Library/include" ^
    -DCMAKE_INSTALL_DATAROOTDIR="Library/share" ^
    -DCMAKE_INSTALL_PREFIX="%PREFIX%" ^
    -DPARAVIEW_USE_VISKORES=OFF ^
    -DPARAVIEW_USE_PYTHON=ON ^
    -DPARAVIEW_USE_FORTRAN=OFF ^
    -DPython3_FIND_STRATEGY=LOCATION ^
    -DPython3_ROOT_DIR="%PREFIX%" ^
    -DPARAVIEW_PYTHON_SITE_PACKAGES_SUFFIX="Lib/site-packages" ^
    -DPARAVIEW_BUILD_WITH_EXTERNAL=ON ^
    -DCGNS_LIBRARY="%LIBRARY_PREFIX%/lib/cgnsdll.lib" ^
    -DPARAVIEW_USE_EXTERNAL_VTK=ON ^
    -DPARAVIEW_ENABLE_WEB=ON ^
    -DPARAVIEW_ENABLE_XDMF3=ON ^
    -DPARAVIEW_ENABLE_EMBEDDED_DOCUMENTATION=OFF ^
    -DPARAVIEW_PLUGIN_DISABLE_XML_DOCUMENTATION=ON ^
    -B build .
if errorlevel 1 exit 1

cmake --build build --target install --config Release --parallel %CPU_COUNT%
if errorlevel 1 exit 1

curl https://www.paraview.org/files/%PKG_VERSION:~0,4%/ParaViewGettingStarted-%PKG_VERSION%.pdf --create-dirs -o %LIBRARY_PREFIX%\doc\GettingStarted.pdf
if errorlevel 1 exit 1
