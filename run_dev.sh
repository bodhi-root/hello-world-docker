#!/bin/bash

docker run --rm -it \
  --network host \
  --mount type=bind,source="$(pwd)",target=/home/developer/project,consistency=consistent \
  dev-hello-world \
  bash
