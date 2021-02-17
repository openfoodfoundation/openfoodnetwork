# frozen_string_literal: true

require 'simplecov'

SimpleCov.minimum_coverage 0
SimpleCov.start 'rails' do
  add_filter '/bin/'
  add_filter '/config/'
  add_filter '/jobs/application_job.rb'
  add_filter '/schemas/'
  add_filter '/lib/generators'
  add_filter '/spec/'
  add_filter '/vendor/'
  add_filter '/public'
  add_filter '/swagger'
  add_filter '/script'
  add_filter '/log'
  add_filter '/db'
end
