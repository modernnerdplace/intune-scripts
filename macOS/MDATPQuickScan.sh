#!/bin/sh
#
# Script to automatically do a quick scan using Microsoft Defender (v2022.5.1)
# (c) Lennart Dreves - LennMedia
#
# NOTE: Script must run in user credentials.

if [[ -f "/usr/local/bin/mdatp" ]] ; then
    /usr/local/bin/mdatp scan quick >/dev/null
fi