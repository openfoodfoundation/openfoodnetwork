#!/usr/bin/env bash

export HOME="/home/ubuntu"
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"

$HOME/apps/ofn_america/current/script/delayed_job $@ -i 0 start
