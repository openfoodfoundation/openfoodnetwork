#!/usr/bin/env bash

export HOME="/home/openfoodweb"
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"

$HOME/apps/openfoodweb/current/script/delayed_job $@
