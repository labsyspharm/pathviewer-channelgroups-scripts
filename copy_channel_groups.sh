#!/bin/bash

# 
# Shell script which copies PathViewer's Channel Groups.
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

IMAGE=$1
IMAGE_IDS="${@:2}"

echo "Copying channel groups from image: ${IMAGE}"
echo "Copying channel groups to images: ${IMAGE_IDS}"

JSON_QUERY="\
    SELECT annotation.textValue from Image as image \
    left outer join image.pixels as pixels \
    left outer join pixels.channels as channels \
    left outer join channels.annotationLinks as links \
    left outer join links.child as annotation \
    WHERE image.id=${IMAGE} AND annotation.ns='pathviewer'"
CHANNEL_QUERY="\
    SELECT min(channel.id) from Image as image \
    left outer join image.pixels as pixels \
    left outer join pixels.channels as channel \
    where image.id="
EXISTING_ANNOTATION_QUERY="\
    Select annotation.id, links.id from Channel as channel \
    left outer join channel.annotationLinks as links \
    left outer join links.child as annotation \
    where annotation.ns='pathviewer' and channel.id="

JSON_STRING=$(omero hql --style plain "${JSON_QUERY}" | cut -d ',' --fields=2- )
echo $JSON_STRING

for IMAGE_ID in $IMAGE_IDS
do
    echo "Creating channel groups for Image ${IMAGE_ID}"
    CHANNEL_ID=$(omero hql --style plain "${CHANNEL_QUERY}${IMAGE_ID}" | cut -d ',' -f 2)
    RESULTS=$(omero hql --style plain "${EXISTING_ANNOTATION_QUERY}${CHANNEL_ID}")
    LINK_ID=$(echo ${RESULTS} | cut -d ',' -f 3)
    EXISTING_ANNOTATION_ID=$( echo ${RESULTS} | cut -d ',' -f 2 )
    if [ -n "${EXISTING_ANNOTATION_ID}" ]; then
        echo "Channel group exist under: ANNOTATION:${EXISTING_ANNOTATION_ID}, LINK:${LINK_ID}"
        continue
    fi
    echo "Attaching channel groups to channel ${CHANNEL_ID}"
    ANNOTATION_ID=$(omero obj new CommentAnnotation "ns=pathviewer" "textValue=${JSON_STRING}" | cut -d ':' -f 2)
    echo "Created annotation ${ANNOTATION_ID}"
    ANNOTATION_LINK_ID=$(omero obj new ChannelAnnotationLink "parent=Channel:${CHANNEL_ID}" "child=CommentAnnotation:${ANNOTATION_ID}" | cut -d ':' -f 2)
    echo "Created channel-annotation link: ${ANNOTATION_LINK_ID}"
done
