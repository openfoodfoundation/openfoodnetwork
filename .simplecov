#!/bin/env ruby
# frozen_string_literal: true

SimpleCov.configure do
  load_profile "rails"

  # The rails profile contains some filters already:
  #
  # - "/test/"
  # - "/features/"
  # - "/spec/"
  # - "/autotest/"
  # - /^\/config\//
  # - /^\/db\//
  skip "/bin/"
  skip "/config/" # to also skip engine config
  skip "/script"  
end
