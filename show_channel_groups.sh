#!/bin/bash

# 
# Shell script which shows PathViewer's Channel Groups.
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

JSON_QUERY="\
    SELECT annotation.textValue from Image as image \
    left outer join image.pixels as pixels \
    left outer join pixels.channels as channels \
    left outer join channels.annotationLinks as links \
    left outer join links.child as annotation \
    WHERE (annotation.ns='pathviewer' or annotation.ns='glencoesoftware.com/pathviewer/channel/settings') \
    AND image.id=${IMAGE}"

JSON_STRING=$(omero hql --style plain "${JSON_QUERY}")

PYTHON_CODE="import sys, csv, json; print(json.dumps(json.loads(next(csv.reader(sys.stdin))[1]), indent=4))"

echo "$JSON_STRING" | python3 -c "$PYTHON_CODE" || echo "$JSON_STRING"
