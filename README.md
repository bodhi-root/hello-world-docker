# Hello World (C and Docker)

## Overview

This project will show how to use docker to create a development environment for C/C++ coding.  The docker setup can be used for any development language, but we will be going a little bit deeper into the compile/make process for C/C++.  The goal is to be able to write C/C++ code on a Windows computer (or any operating system that supports docker) and compile the code in a docker environment that ensures every developer is compiling the code in the exact same way with the same set of tools.  This will also make it easier to compile your code for different target systems since you can create a docker environment that mimics your target system and compile the code there.

The high-level process we'll cover involves:

1. Install your IDE of choice and write some code
2. Building a docker container for your compiling environment
3. Run the docker container with a mount to expose your development directory
4. Compile your code

Steps 1-3 are applicable to use cases other than C/C++ (although the docker container we'll build will be designed for compiling C code).  Step 4 is the only step that really involve C/C++ specifically.

We'll also provide some links to useful resources.

## Step-by-Step Instructions

### Step 1: Install IDE and write some code

The process we're using does not depend on how you write your code.  I'm using VSCode as I write this just because it has nice syntax-highlighting for C/C++ and a lot of developers use it for that purpose.  While VSCode does provide extensions for integrating docker as a development environment and auto-completing C/C++ code (if you can link it to your compilation environment) we won't be using any of those.  This means you can write your code with anything (even Notepad or vim), so pick your favorite IDE (or no IDE at all) and use it!

To begin, we'll just write one source file named 'main.c' and place it in a directory named 'src'.  This file contains your basic "Hello world" code:

```c
#include <stdio.h>
 
int main()  {
    printf("Hello world!\n\n");
    return 0;
}
```

But now that we've written this amazing piece of code, how the heck do we compile and run it?  Well, that's why we're here, isn't it?  Let's go!

NOTE: Ignoring VSCode's built-in extensions is done intentionally so that we are not dependent on a specific IDE and so that the process we use can be applied to other programming languages as well.  If you like VSCode and want to make it a dependency for your work, feel free to.  You'll probably get a better, more integrated experience, but I'd prefer my process to be tool-agnostic since I often develop in different languages with different IDEs for each language.

### Step 2: Build a docker container for your compiling environment

The Dockerfile we'll use for our development environment looks like this:

```Dockerfile
FROM ubuntu:22.04
LABEL Description="Dev environment"

# Install build tools
RUN apt-get update && apt-get -y --no-install-recommends install \
    build-essential \
    clang \
    cmake \
    gdb \
    wget \
    sudo

# Create user 'developer'
RUN useradd --create-home --shell /bin/bash developer \
    && echo 'developer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER developer
WORKDIR /home/developer

# Create project directory:
RUN mkdir project
WORKDIR /home/developer/project

ENTRYPOINT "bash"
```

This is a simple Ubuntu system with basic tools for compiling C/C++.  We create a user named "developer" and a directory "/home/developer/project" that we will use to expose our project and source code from our host system.  Note that we give the "developer" user access to run ```sudo``` without using a password (and install sudo) so that they can perform actions that would normally require root access on the container.

We save the above as ```.devcontainer/Dockerfile```.  This mimics the setup VSCode uses even though we aren't using the extension that makes use of it.  The goal is just to separate the Dockerfile for our development environment from any Dockerfile we might create to run our project in a production environment (which would be named ```Dockerfile``` and located in the root directory of our project).  If we wanted to build in multiple environments we could define multiple Dockerfiles and change the steps below for building and running those images as needed.

With only one ```Dockerfile``` located in the ```.devcontainer``` directory, we can build our development image by running ```./build_dev.sh``` which contains:

```bash
#!/bin/bash
docker build -t "dev-hello-world" \
  --network host \
  -f ".devcontainer/Dockerfile" .
```

If this builds successfully, you will have a new docker image registered on your host system named "dev-hello-world".

### Step 3: Run the docker container

We'll run the container with the ```./run_dev.sh``` script.  This contains:

```bash
#!/bin/bash
docker run --rm -it \
  --network host \
  --mount type=bind,source="$(pwd)",target=/home/developer/project,consistency=consistent \
  dev-hello-world \
  bash
```

This runs the "dev-hello-world" image in the foreground in interactive mode.  The important thing to note here is the ```--mount``` option that will mount your local project directory to ```/home/developer/project``` on the container.  When the container starts, you will be in the ```/home/developer/project``` directory and will see all of the files in your project directory appearing there.

The mount is important because it allows you to:

1. Edit files on your local computer and have the changes immediately visible in the running container.  (This is the reason you can use any IDE on your host system for development.)
2. Edit files in the running container and have the changes show up on your host system (if you want).
3. Compile the code in your container and have the outputs show up on your host system.

If you need to install additional tools in your development environment you can do so by editing the Dockerfile, rebuilding the image, and running the container again.  You can also install tools temporarily from within the container, but they will disappear after the container is stopped.  You may want to do this for things such as troubleshooting network connectivity.  Since the ```ping``` command isn't available in the container, you can install it with:

```sudo apt-get install iputils-ping```

After this installs, the ```ping``` command will be available to run tests such as ```ping 8.8.8.8```.

### Step 4: Compile your code

Since we only have one source code file in our project, we can easily compile it with ```gcc``` and run the code with:

```bash
cd src
gcc -o helloworld main.c
./helloworld
```

The ```gcc``` command will compile ```hello.c``` and create an executable named ```helloworld``` which we then run.  This ```helloworld``` executable will also be available on our host system although it will likely not run unless our host environment is similar to the development environment.

For larger projects, you will want to use tools such as "cmake" to compile your project.  To use cmake with our current project, we create a file named ```CMakeLists.txt``` in our project directory containing:

```
project(HelloWorld)
cmake_minimum_required(VERSION 3.0)
add_executable(helloworld src/main.c)
```

cmake will automate the creation of a Makefile that will actually compile our project.  It is recommended that you compile in a ```build``` directory separate from your source code to keep things clean.  You can do this by running:

```bash
mkdir build
cd build
cmake ..
make
```

Since we are in the ```build``` directory, we use ```cmake ..``` to indicate that we want to run ```cmake``` in the context of the parent directory (our root project directory).  This generates a ```Makefile``` and a couple other files in our ```build``` directory but leaves the other project directories alone.  We then run ```make``` to use this ```Makefile``` to compile our code and create the ```helloworld``` executable.  This will also be created in the ```build``` directory without affecting the rest of our project.

When your project gets bigger, you'll have multiple source files and maybe some public header files to expose as well.  As an example, our project has the following files:

* src/
  * hello.c
  * main.c
* include/
  * hello.h

"hello.c" has a simple "say_hello()" function and "hello.h" is the header file defining that function.  Our "main.c" program has been modified to include "hello.h" and to print say hello to "Daniel" in addition to our original "Hello world!" message.  The following CMakeLists.txt file can be used to compile this program:

```
project(HelloWorld)
cmake_minimum_required(VERSION 3.0)

include_directories("include")
file(GLOB SOURCES "src/*.c")

add_executable(helloworld ${SOURCES}) 
```

The ```file(GLOB SOURCES "src/*.c")``` line will find all files matching "src/*.c" and put them in a variable named "SOURCES".  We then refer to this variable in the "add_executable" line.  Alternately, we could specify each of the source files manually with something like:

```
set(SOURCES, "src/main.c" "src/hello.c")
```

We can then compile our program in exactly the same way as we did before by going to the "build" directory and running "cmake .." followed by "make".

There's plenty more to learn about the details of cmake and writing/organizing C/C++ projects, but this should be enough to get going.  We'll conclude with some thoughts on project layout and notes about committing your project to git, and then you can start having fun coding!

## Project Layout

So far we have followed the convention of putting source code files in a directory named "src", header files in a directory named "include", and using the "build" directory as a place to compile and build our project.  This directory structure is fairly common.  It is a subset of the best practices described here:

* https://api.csswg.org/bikeshed/?force=1&url=https://raw.githubusercontent.com/vector-of-bool/pitchfork/develop/data/spec.bs

If you extend your project beyond this by adding things like documentation, data, and sample code that link can provide good ideas on organizing all of those into subdirectories.  In short, the full set of top-level directories they recommend:

* src - Source code (and private headers)
* include - Public API headers
* data - Data files (non code) used by your project
* docs - Project documentation
* build - Empty directory (does not need to be in git) used for building
* tests - Source files related to (non-unit) tests
* examples - Source files related to example and sample usage
* external - Embedding external projects (one project per subdirectory)
* tools - Extra scripts and tools related to developing and contributing to the project
* libs - Used for submodules (each of these can contain its own 'src', 'include', etc. directories)
* extras - A submodule for anything else

If we followed this convention 100%, we should probably put our "build_dev.sh" and "run_dev.sh" scripts into the "tools" directory, but I didn't want to deal with all the ".." relative path references that would result from that.

## Git Notes

When you put your project into git there are two important things to watch out for:

1. You'll want to add "/build" to your ".gitignore" file so you don't put your build files into the repo
2. You'll want to setup ".gitattributes" to checkout files using Linux newlines (LF)

This second step is especially important if some of your developers are working on Windows machines.  Windows users will still need to ensure that their IDE is not putting Windows newlines (CRLF) into files they create and edit, but the ".gitattributes" file can ensure they aren't introducing Windows newlines when they checkout the code.  This can be done by creating a ```.gitattributes``` file that contains the following:

```
* text=auto eol=lf
```

This instructs git to checkout all text files with Linux-style newlines (LF) instead of Windows-style (CRLF).  Without this, you might end up creating files on your Windows computer with CRLF newlines that won't run correctly in your Linux development environment.  A good example of this is shell scripts that begin with ```#!/bin/bash```.  When CRLF newlines are used, the Linux system will complain that it can't file the program ```/bin/bash/^M``` where ```^M``` indicates the hidden newline character.

The ```text=auto``` part of the above directory tells git to use its own method to determine whether a file is text or binary.  This works in git 2.10 (released September 2016) and above.  In older versions (or if you want more control) you will need to specify files as text or binary more explicitly.  You can use a command such as ```* text eol=lf``` to indicate that all files should be treated as text with LF newlines by default.  Then you can identify specific files as binary.  For example:

```
* text eol=lf
*.png binary
*.pdf binary
```

## Summary

Hopefully this project has provided a starting point and some reference code for setting up a Docker container on your computer to use as a development environment.  This can be used for many different types of projects, not just C/C++, and will ensure that your developers are all using the exact same environment when they are creating, building, and testing the project.  This is especially helpful for developers working on Windows who want to develop and test code in a Linux environment that more closely resembles the production environment.  It can also be helpful if you want to build or test your project in different Linux environments to ensure it compiles and runs as expected there.

If your experience on Windows is like mine, you'll probably run into a shit ton of other errors when you try to install and run Docker (especially if you try to run it on WSL like I did), but that process and those issues are documented elsewhere.  Once you get docker running successfully in your environment, you're pretty close to the goal of developing and compiling code in that environment.  The sample code and instructions here will hopefully get you the rest of the way to the finish line so you can begin your real work.  Happy coding!
