# Minimum CMake required
cmake_minimum_required(VERSION 2.8)

# Project
project(HelloWorld CXX)
set(CMAKE_CXX_STANDARD 14)

# Protobuf
find_package(Protobuf 3.0 REQUIRED)

# gRPC
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR})
find_package(GRPC REQUIRED)

set(hw_proto_SRCS
  helloworld.proto
  )

# Run C++ protocol buffer compiler
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS ${hw_proto_SRCS})

# Run gRPC C++ protocol buffer compiler
protobuf_generate_grpc_cpp(GRPC_SRCS GRPC_HDRS ${hw_proto_SRCS})

# Get include directories for generated headers
set(_proto_include_dirs)
foreach(header ${PROTO_HDRS})
  get_filename_component(_proto_dir ${header} DIRECTORY)
  list(FIND _proto_include_dirs _proto_dir _proto_idx)
  if (${_proto_idx} EQUAL -1)
    list(APPEND _proto_include_dirs ${_proto_dir})
  endif()
endforeach()

# Generated include directory
include_directories("${CMAKE_CURRENT_BINARY_DIR}")
include_directories(${Protobuf_INCLUDE_DIRS})
include_directories(${_proto_include_dirs})

# Targets greeter_(client|server)
foreach(_target
  greeter_client greeter_server)
  add_executable(${_target} "${_target}.cc"
    ${PROTO_SRCS}
    ${GRPC_SRCS})
  target_link_libraries(${_target}
    ${Protobuf_LIBRARIES}
    ${GRPC_ALL_LIBRARIES})
    if (WIN32)
      target_link_libraries(${_target} Ws2_32.lib) # winsock functions bind, closesocket etc
    endif()
endforeach()
