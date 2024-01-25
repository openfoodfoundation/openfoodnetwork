#!/usr/bin/env ruby
# frozen_string_literal: true

# Upgrade HAML attribute syntax to prepare for HAML 6.
#
# HAML 6 stopped supporting nested hash attributes other than `data` and `aria`.
# We used to be able to write:
#
#     %div{ ng: { class: "upper", bind: "model" } }
#
# This needs to be written in a flat structure now:
#
#     %div{ "ng-class" => "upper", "ng-bind" => "model" }
#
# This script rewrites HAML files automatically. It may be used like:
#
#     git ls-files '*.haml' | while read f; do ./haml-up.rb "$f"; done
#
require "haml_up"

puts ARGV[0]
HamlUp.new.upgrade_file(ARGV[0])
