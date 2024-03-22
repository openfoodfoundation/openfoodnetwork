#!/bin/bash
#
# Install our selected Ruby version defined in the .ruby-version file.
#
# Requires:
# - [rvm](https://rvm.io/)
#

rvm install $RUBY_VERSION
