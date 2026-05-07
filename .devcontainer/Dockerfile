FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    flatpak \
    flatpak-builder \
    elfutils \
    git \
    curl \
    binutils \
    xz-utils \
    zstd \
    fuse3 \
    dpkg \
    file \
    patchelf \
    && rm -rf /var/lib/apt/lists/*

RUN flatpak remote-add --system --if-not-exists flathub \
      https://flathub.org/repo/flathub.flatpakrepo

RUN flatpak install --system --noninteractive flathub \
      org.freedesktop.Platform//24.08 \
      org.freedesktop.Sdk//24.08

WORKDIR /workspace
