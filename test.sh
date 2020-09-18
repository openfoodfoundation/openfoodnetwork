#!/bin/bash
set -e

DATE=`date +%Y%m%d-%H%M%S-%3N`
bash test-log.sh 2>&1 | tee log/test-$DATE.log
