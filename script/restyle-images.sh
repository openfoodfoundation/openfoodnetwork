#!/bin/bash
#
# Starts and resumes reprocessing of all thumbnail images.

set -e

log="log/images-restyle.log"
last_id="0"
styles="$1"

if [ -r "$log" ]; then
  last_id="$(tail -1 "$log" | sed 's/^processing Spree::Image ID \([0-9]*\): done.$/\1/')"
fi

bundle exec rake images:restyle\
  CLASS=Spree::Image\
  AFTER_ID="$last_id"\
  STYLE_DEFS="$styles"\
  >> "$log"
