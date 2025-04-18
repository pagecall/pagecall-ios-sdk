# libmediasoup iOS build file

cmake_minimum_required(VERSION 3.5)

set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
project(Project)

# C++ requirements
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD REQUIRED ON)

# build for iphone or simulator
# default is iphone
if(NOT IOS_SDK)
  message(FATAL_ERROR "IOS_SDK not provided (iphone/iphonesimulator)")
endif()

if(NOT IOS_ARCHS)
  message(FATAL_ERROR "IOS_ARCHS not provided")
endif()

# Set the sdk to build with
if("${IOS_SDK}" STREQUAL "iphone")
  set(CMAKE_OSX_SYSROOT "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/")
elseif("${IOS_SDK}" STREQUAL "iphonesimulator")
  set(CMAKE_OSX_SYSROOT "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk")
else()
  message(FATAL_ERROR "IOS_SDK must be set to iphone/iphonesimulator")  
endif()

# set the ios architectures
set(CMAKE_OSX_ARCHITECTURES ${IOS_ARCHS})

# set mediasoup flags
set(LIBSDPTRANSFORM_BUILD_TESTS OFF)
set(LIBSDPTRANSFORM_BUILD_READMEHELPER OFF)

# Set the sdk version and the min sdk version
set(IPHONE_SDKVER "14.0")
set(IPHONE_VERSION_MIN "14.0")

message(STATUS "\n========== libmediasoupclient iOS Build Configuration ==========\n")
message(STATUS "CMAKE_OSX_SYSROOT             = " ${CMAKE_OSX_SYSROOT})
message(STATUS "CMAKE_OSX_ARCHITECTURES       = " ${CMAKE_OSX_ARCHITECTURES})

# Source dependencies
add_subdirectory("libmediasoupclient")
