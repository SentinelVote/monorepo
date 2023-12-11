#!/bin/sh

drawio -x PrototypeSlides.drawio -o PrototypeSlides.png
git add ./*
git commit -m 'drawio: update deliverable diagrams'
git commit
