#!/usr/bin/env bash

echo "Run SwiftFormat stage"

if which "Tools/swiftformat/bin/swiftformat" >/dev/null; then

    echo "Run SwiftFormat: > Tools/swiftformat/bin/swiftformat ."
    Tools/swiftformat/bin/swiftformat .
else
    echo "warning: SwiftFormat not installed, download it from https://github.com/nicklockwood/SwiftFormat/releases"
    exit -1
fi
