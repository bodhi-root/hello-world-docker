project(HelloWorld)
cmake_minimum_required(VERSION 3.0)

include_directories("include")
file(GLOB SOURCES "src/*.c")

add_executable(helloworld ${SOURCES}) 
