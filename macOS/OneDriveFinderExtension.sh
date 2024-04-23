#!/bin/sh
#
# Script to enable the Finder Extension for OneDrive (v2023.6.1)
# (c) Lennart Dreves - LennMedia
#
# NOTE: Script must run in user credentials.

# Wait for OneDrive to be installed
while [[ $ready -ne 1 ]];do
    if [[ -a "/Applications/OneDrive.app" ]]; then
        ready=1
    else
        sleep 60
    fi
done

# Get extension name (differs between standalone and VPP version)
if pluginkit -m | grep "com.microsoft.OneDrive-mac.FinderSync"; then
    ExtensionName="com.microsoft.OneDrive-mac.FinderSync"
fi

if pluginkit -m | grep "com.microsoft.OneDrive.FinderSync"; then
    ExtensionName="com.microsoft.OneDrive.FinderSync"
fi

# Check if the extension is already enabled and enable it
if ! pluginkit -m | grep "+    $ExtensionName"; then
    pluginkit -e use -i $ExtensionName
fi