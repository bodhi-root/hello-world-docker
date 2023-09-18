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
