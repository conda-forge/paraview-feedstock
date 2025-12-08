#!/bin/bash

set -x

mkdir smoke_test_dir
cd smoke_test_dir || exit

cat <<- EOF > CMakeLists.txt
cmake_minimum_required(VERSION 3.16)
project(ParaViewSmokeTest)

find_package(ParaView REQUIRED)
add_executable(paraview_smoke_test main.cpp)
target_link_libraries(paraview_smoke_test
  PRIVATE
    ParaView::RemotingCore
    ParaView::RemotingServerManager
    VTK::CommonCore
    VTK::CommonDataModel
)
set_target_properties(paraview_smoke_test PROPERTIES
  CXX_STANDARD 11
  CXX_STANDARD_REQUIRED ON
)

EOF

cat <<- EOF > main.cpp
#include <vtkInitializationHelper.h>
#include <vtkProcessModule.h>

int main(int argc, char* argv[])
{
  vtkInitializationHelper::Initialize(argc, argv, vtkProcessModule::PROCESS_CLIENT);
  vtkInitializationHelper::Finalize();
  return 0;
}
EOF

maybe_build_native=
if test "${CONDA_BUILD_CROSS_COMPILATION}" == "1"; then
	export CC=$CC_FOR_BUILD
  export CXX=$CXX_FOR_BUILD
	maybe_build_native=(-B build-native)
fi

cmake -G "Ninja" -DCMAKE_PREFIX_PATH="${PREFIX}" -DCMAKE_BUILD_TYPE=Release "${maybe_build_native[@]}" .
cmake build .

if test -z "${CONDA_BUILD_CROSS_COMPILATION}"; then
  ./bin/paraview_smoke_test
fi
