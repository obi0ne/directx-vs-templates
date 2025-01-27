cmake_minimum_required (VERSION 3.13)

project(CMakeDirect3D12Game
  DESCRIPTION "CMake example for Direct3D 12 Game (UWP)"
  LANGUAGES CXX)

option(BUILD_TEST_TEMPLATE "Ignore warnings related to TODOs" OFF)

option(ENABLE_CODE_ANALYSIS "Use Static Code Analysis on build" OFF)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/CMake")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/CMake")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/CMake")

add_executable(${PROJECT_NAME} WIN32
    Game.cpp
    Game.h
    Main.cpp
    StepTimer.h
    pch.h
    d3dx12.h
)

target_compile_definitions(${PROJECT_NAME} PRIVATE "$<$<CONFIG:DEBUG>:_DEBUG>" "$<$<CONFIG:RELEASE>:NDEBUG>")

if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.16")
    target_precompile_headers(${PROJECT_NAME} PRIVATE pch.h )
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE
    d3d12.lib dxgi.lib dxguid.lib uuid.lib)

if(MSVC)
    # Use max Warning Level 
    string(REPLACE "/W3 " "/Wall " CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
    string(REPLACE "/W3 " "/Wall " CMAKE_CXX_FLAGS_DEBUG ${CMAKE_CXX_FLAGS_DEBUG})
    string(REPLACE "/W3 " "/Wall " CMAKE_CXX_FLAGS_RELEASE ${CMAKE_CXX_FLAGS_RELEASE})

    target_compile_options(${PROJECT_NAME} PRIVATE /fp:fast)

    if((${CMAKE_SIZEOF_VOID_P} EQUAL 4) AND (NOT ${DIRECTX_ARCH} MATCHES "arm"))
        target_compile_options(${PROJECT_NAME} PRIVATE /arch:SSE2)
    endif()

    target_link_options(${PROJECT_NAME} PRIVATE /DYNAMICBASE /NXCOMPAT)
endif()

if (VCPKG_TOOLCHAIN)
    message("INFO: Using VCPKG for DirectX-Headers and DirectXMath.")
    find_package(directx-headers CONFIG REQUIRED)
    find_package(directxmath CONFIG REQUIRED)
    target_link_libraries(${PROJECT_NAME} PRIVATE Microsoft::DirectX-Headers Microsoft::DirectXMath)
    target_compile_definitions(${PROJECT_NAME} PRIVATE USING_DIRECTX_HEADERS)

    # Uncomment if using the DirectX Tool Kit
    # find_package(directxtk12 CONFIG REQUIRED)
    # target_link_libraries(${PROJECT_NAME} PRIVATE Microsoft::DirectXTK12)
endif()

if ( CMAKE_CXX_COMPILER_ID MATCHES "Clang" )
    target_compile_options(${PROJECT_NAME} PRIVATE
        -Wpedantic -Wextra
        "-Wno-c++98-compat" "-Wno-c++98-compat-pedantic"
        "-Wno-exit-time-destructors" "-Wno-global-constructors" "-Wno-language-extension-token"
        "-Wno-missing-prototypes" "-Wno-missing-variable-declarations" "-Wno-reserved-id-macro"
        "-Wno-float-equal" "-Wno-switch-enum" "-Wno-tautological-type-limit-compare")

    target_compile_definitions(${PROJECT_NAME} PRIVATE _SILENCE_CLANG_COROUTINE_MESSAGE)

    if(BUILD_TEST_TEMPLATE)
        target_compile_options(${PROJECT_NAME} PRIVATE "-Wno-unused-value")
    endif()
endif()
if ( CMAKE_CXX_COMPILER_ID MATCHES "MSVC" )
    target_compile_options(${PROJECT_NAME} PRIVATE
         /permissive- /Zc:__cplusplus
         "/wd4061" "/wd4265" "/wd4297" "/wd4355" "/wd4365" "/wd4371" "/wd4514" "/wd4555"
         "/wd4571" "/wd4623" "/wd4625" "/wd4626" "/wd4668" "/wd4710" "/wd4820" "/wd4946"
         "/wd5026" "/wd5027" "/wd5039" "/wd5045" "/wd5204" "/wd5220")

    target_compile_options(${PROJECT_NAME} PRIVATE /await)

    if(ENABLE_CODE_ANALYSIS)
        target_compile_options(${PROJECT_NAME} PRIVATE /analyze)
    endif()

    if (CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.24)
        target_compile_options(${PROJECT_NAME} PRIVATE /ZH:SHA_256)
    endif()

    if (CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.26)
        target_compile_options(${PROJECT_NAME} PRIVATE /Zc:preprocessor /wd5105)
    endif()

    if ((CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.27) AND (NOT (${DIRECTX_ARCH} MATCHES "arm(64)?")))
        target_link_options(meshconvert PRIVATE /CETCOMPAT)
    endif()

    if(BUILD_TEST_TEMPLATE)
        target_compile_options(${PROJECT_NAME} PRIVATE "/wd4555")
    endif()
endif()

if(WIN32)
    target_compile_definitions(${PROJECT_NAME} PRIVATE _WIN32_WINNT=0x0A00 WINAPI_FAMILY=WINAPI_FAMILY_APP)
endif()

set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME})

# The Package.appxmanifest works for development purposes, but is currently missing
# Identity ProcessorArchitecture, TargetDeviceFamily MaxVersionTested, and the
# Dependencies block for the C/C++ Runtime.
# http://go.microsoft.com/fwlink/?LinkID=241727
configure_file(Package.appxmanifest AppxManifest.xml @ONLY)

add_custom_command(
  TARGET ${PROJECT_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy
    ${CMAKE_CURRENT_BINARY_DIR}/AppxManifest.xml
    $<TARGET_FILE_DIR:${PROJECT_NAME}>
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_CURRENT_SOURCE_DIR}/Assets
    $<TARGET_FILE_DIR:${PROJECT_NAME}>/Assets
    )

# Loose install from PowerShell
# Add-AppxPackage -Register <cmake_binary_dir>\bin\CMake\AppxManifest.xml
#
# Visual Studio: Debug -> Other Debug Targets -> Debug Installed App Package...
#
# Remove from PowerShell
# Get-AppxPackage -Name <guid-in-package.appxmanifest> | Remove-AppxPackage
