#! /usr/bin/env sh

sudo snap install --edge remarkable-desktop
sudo snap install wine-platform-runtime-core22
sudo snap install wine-platform-7-stable-core22

sudo snap connect remarkable-desktop:wine-runtime-c22 wine-platform-runtime-core22
sudo snap connect remarkable-desktop:wine-7-stable-c22 wine-platform-7-stable-core22
