#!/bin/bash

# 
# Shell script which removes PathViewer's Channel Groups.
#
# Copyright (c) 2017 Glencoe Software, Inc. All rights reserved.

# This program and the accompanying materials
# are licensed and made available under the terms and conditions of the BSD
# License which accompanies this distribution.  The full text of the license
# may be found at http://opensource.org/licenses/bsd-license.php
#
# THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
# WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED.
#

IMAGE_IDS="${@:1}"

echo "Removing channel groups from: ${IMAGE_IDS}" 

CHANNEL_QUERY="\
    SELECT min(channel.id) from Image as image \
    left outer join image.pixels as pixels \
    left outer join pixels.channels as channel \
    where image.id=" 
EXISTING_ANNOTATION_QUERY="\
    Select annotation.id, links.id from Channel as channel \
    left outer join channel.annotationLinks as links \
    left outer join links.child as annotation \
    where (annotation.ns='pathviewer' or annotation.ns='glencoesoftware.com/pathviewer/channel/settings') \
    and channel.id="

for IMAGE_ID in $IMAGE_IDS
do
    echo "Removing channel groups for Image ${IMAGE_ID}" 
    CHANNEL_ID=$(omero hql --style plain "${CHANNEL_QUERY}${IMAGE_ID}" | cut -d ',' -f 2)
    RESULTS=$(omero hql --style plain "${EXISTING_ANNOTATION_QUERY}${CHANNEL_ID}")
    EXISTING_ANNOTATION_ID=$( echo ${RESULTS} | cut -d ',' -f 2 )
    if [ -z "${EXISTING_ANNOTATION_ID}" ]; then
        echo "No channel groups found for: Image: ${IMAGE_ID}, Channel: ${CHANNEL_ID}" 
        continue
    fi
    echo "Removing channel groups attached to channel ${CHANNEL_ID}" 
    ANNOTATION_ID=$(omero delete CommentAnnotation:${EXISTING_ANNOTATION_ID} | cut -d ':' -f 2)
    echo "Removed annotation ${ANNOTATION_ID}" 
done
