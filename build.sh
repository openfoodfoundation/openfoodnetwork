#!/bin/bash
set -e

DATE=`date +%Y%m%d-%H%M%S-%3N`
bash build-log.sh 2>&1 | tee log/build-$DATE.log
bash seed.sh 2>&1 | tee log/seed-$DATE.log
