#!/bin/env ruby
# frozen_string_literal: true

SimpleCov.start 'rails' do
  add_filter '/bin/'
  add_filter '/config/'
  add_filter '/script'
  add_filter '/db'

  # We haven't managed to make simplecov recognise rake coverage accurately.
  add_filter '/lib/tasks/'

  formatter SimpleCov::Formatter::SimpleFormatter
end
