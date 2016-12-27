# FindGRPC
#
# Based on https://github.com/wastl/cmarmotta/blob/b2c36f357b5336dd4da31259cec490762ed6e996/cmake/FindGRPC.cmake
# which is likely based on http://stackoverflow.com/questions/32823563/using-cmake-to-create-protobuf-grpc-cc-files
# and uses the Apache 2.0 License.
#
# Also see https://github.com/grpc/grpc/issues/6573 (Issue to provide FindGRPC.cmake in grpc).

# Internal function: search for normal library as well as a debug one
#    if the debug one is specified also include debug/optimized keywords
#    in *_LIBRARIES variable (adapted from FindProto.cmake)
function(_grpc_find_libraries name filename)
  if(${name}_LIBRARIES)
    # Use result recorded by a previous call.
    return()
  elseif(${name}_LIBRARY)
    # Honor cache entry used by CMake 3.5 and lower.
    set(${name}_LIBRARIES "${${name}_LIBRARY}" PARENT_SCOPE)
  else()
    find_library(${name}_LIBRARY_RELEASE
      NAMES ${filename}
      PATHS ${GRPC_INCLUDE_DIR}/../bin/grpc/release)
    mark_as_advanced(${name}_LIBRARY_RELEASE)

    find_library(${name}_LIBRARY_DEBUG
      NAMES ${filename}
      PATHS ${GRPC_INCLUDE_DIR}/../bin/grpc/debug)
    mark_as_advanced(${name}_LIBRARY_DEBUG)

    select_library_configurations(${name})
    set(${name}_LIBRARY "${${name}_LIBRARY}" PARENT_SCOPE)
    set(${name}_LIBRARIES "${${name}_LIBRARIES}" PARENT_SCOPE)
  endif()
endfunction()

find_path(GRPC_INCLUDE_DIR NAMES grpc DOC "A path to gRPC's include folder")
_grpc_find_libraries(GRPC grpc)
_grpc_find_libraries(GRPC_CPP grpc++)
_grpc_find_libraries(GRPC_GPR gpr)
find_program(GRPC_CPP_PLUGIN grpc_cpp_plugin) # Get full path to plugin
include_directories(${GRPC_INCLUDE_DIR})

if(WIN32)
  # support Vista and newer (gRPC requires _WIN32_WINNT to be defined)
  add_definitions(-D_WIN32_WINNT=0x0600)
  # 0x0600 // Windows Vista
  # 0x0601 // Windows 7
  # 0x0602 // Windows 8
  # 0x0603 // Windows 8.1
  # 0x0A00 // Windows 10
endif()
set(GRPC_ALL_LIBRARIES ${GRPC_CPP_LIBRARIES} ${GRPC_LIBRARIES} ${GRPC_GPR_LIBRARIES})
if(GRPC_ALL_LIBRARIES)
    message(STATUS "Found GRPC:\n GRPC_ALL_LIBRARIES: ${GRPC_ALL_LIBRARIES}\n plugin: ${GRPC_CPP_PLUGIN}")
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GRPC
  REQUIRED_VARS GRPC_INCLUDE_DIR GRPC_LIBRARY GRPC_CPP_PLUGIN GRPC_CPP_LIBRARY GRPC_GPR_LIBRARY
  )

function(PROTOBUF_GENERATE_GRPC_CPP SRCS HDRS)
  if(NOT ARGN)
    message(SEND_ERROR "Error: PROTOBUF_GENERATE_GRPC_CPP() called without any proto files")
    return()
  endif()

  if(PROTOBUF_GENERATE_CPP_APPEND_PATH) # This variable is common for all types of output.
    # Create an include path for each file specified
    foreach(FIL ${ARGN})
      get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
      get_filename_component(ABS_PATH ${ABS_FIL} PATH)
      list(FIND _protobuf_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _protobuf_include_path -I ${ABS_PATH})
      endif()
    endforeach()
  else()
    set(_protobuf_include_path -I ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  if(DEFINED PROTOBUF_IMPORT_DIRS)
    foreach(DIR ${PROTOBUF_IMPORT_DIRS})
      get_filename_component(ABS_PATH ${DIR} ABSOLUTE)
      list(FIND _protobuf_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _protobuf_include_path -I ${ABS_PATH})
      endif()
    endforeach()
  endif()

  set(${SRCS})
  set(${HDRS})
  foreach(FIL ${ARGN})
    get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
    get_filename_component(FIL_WE ${FIL} NAME_WE)

    list(APPEND ${SRCS} "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.grpc.pb.cc")
    list(APPEND ${HDRS} "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.grpc.pb.h")

    add_custom_command(
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.grpc.pb.cc"
             "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.grpc.pb.h"
      COMMAND  ${PROTOBUF_PROTOC_EXECUTABLE}
      ARGS --grpc_out=${CMAKE_CURRENT_BINARY_DIR}
           --plugin=protoc-gen-grpc=${GRPC_CPP_PLUGIN}
           ${_protobuf_include_path} ${ABS_FIL}
      DEPENDS ${ABS_FIL} ${PROTOBUF_PROTOC_EXECUTABLE}
      COMMENT "Running gRPC C++ protocol buffer compiler on ${FIL}"
      VERBATIM)
  endforeach()

  set_source_files_properties(${${SRCS}} ${${HDRS}} PROPERTIES GENERATED TRUE)
  set(${SRCS} ${${SRCS}} PARENT_SCOPE)
  set(${HDRS} ${${HDRS}} PARENT_SCOPE)
endfunction()

