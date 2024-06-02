#!/bin/bash
PLATFORM="x86_64-linux"
INSTALL_DIR=$HOME/.local/share/zig
PATH_DIR=$HOME/.local/bin
PAGE_JSON=$(curl https://ziglang.org/download/index.json)
VERSION=$(echo $PAGE_JSON | jq -r '.["master"]["version"]')
TARBALL_URL=$(echo $PAGE_JSON | jq -r '.["master"]["'"$PLATFORM"'"]["tarball"]')

ZLS_URL="https://github.com/zigtools/zls"

echo "Downloading version $VERSION"
echo "URL: $TARBALL_URL"

mkdir -p .tmp
curl $TARBALL_URL --output .tmp/zig.tar.xz

rm -rf $INSTALL_DIR
rm -f 
mkdir -p $INSTALL_DIR
tar -xf .tmp/zig.tar.xz -C $INSTALL_DIR --strip-components=1
ln -fs $INSTALL_DIR/zig $PATH_DIR/zig

# ZLS
echo "Installing ZLS"
git clone $ZLS_URL .tmp/zls
(cd .tmp/zls && \
  zig build -Doptimize=ReleaseSafe)


# Cleanup
rm -rf .tmp
echo "All Done!"
