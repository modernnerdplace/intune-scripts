#!/bin/sh
#
# Script to Secure Home Folders in macOS (v2022.11.2)
# (c) Lennart Dreves - LennMedia
#

for directory in "/Users/"*; do
    if [[ $directory == "/Users/Shared" ]]; then
        # Skip /Users/Shared folder
        continue
    fi
    sudo chmod -R og-rw $directory
done
