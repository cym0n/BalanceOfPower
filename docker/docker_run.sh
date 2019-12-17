#!/bin/bash

mkdir -p $HOME/documents/bop-data;
docker run \
    -d \
    --name balance_of_power \
    -p=3000:3000 \
    -v=$HOME/documents/bop-data:/var/lib/mongodb \
    bop
