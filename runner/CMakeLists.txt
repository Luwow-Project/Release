add_executable(Luwow.Runner)
target_include_directories(Luwow.Runner PRIVATE
    ${LIBRARY_ROOT}
    ${RUNNER_ROOT}
    ${LIBUV_ROOT}/include
    ${ENGINE_ROOT}
)

target_link_libraries(Luwow.Runner PRIVATE
    Luwow.Engine
    Luwow.TaskLibrary
    Luwow.FsLibrary
    Luau.Ast
    Luau.Compiler
    Luau.VM
    Luau.Common
    uv_a
)

set_target_properties(Luwow.Runner PROPERTIES OUTPUT_NAME runscriptwithlibs)
target_sources(Luwow.Runner PRIVATE main.cpp)
