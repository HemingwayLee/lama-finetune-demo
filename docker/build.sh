#!/bin/bash

BASEDIR="$(dirname $0)"

# CPU-only image, built for linux/amd64 (the arch the pinned torch==1.8.1+cpu
# wheels are published for). Docker transparently emulates this via QEMU on
# other host architectures (e.g. Apple Silicon), so no GPU/CUDA driver is needed.
docker build --platform linux/amd64 -t ywlee/lama -f "$BASEDIR/Dockerfile" "$BASEDIR"
