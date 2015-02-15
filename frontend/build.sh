#! /bin/bash

rm -rf build
mkdir build

cp -r /data/taiga/dist build
cp -r /data/taiga/static build

sudo docker build -t i-taiga-front .

rm -rf build
