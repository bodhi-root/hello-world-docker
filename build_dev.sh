#!/bin/bash

docker build -t "dev-hello-world" \
  --network host \
  -f ".devcontainer/Dockerfile" .
