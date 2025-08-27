#!/bin/env ruby
# frozen_string_literal: true

SimpleCov.start 'rails' do
  # The rails profile contains some filters already:
  #
  # - "/test/"
  # - "/features/"
  # - "/spec/"
  # - "/autotest/"
  # - /^\/config\//
  # - /^\/db\//
  add_filter '/bin/'
  add_filter '/config/' # to include engine config
  add_filter '/script'

  formatter SimpleCov::Formatter::SimpleFormatter
end
