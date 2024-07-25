#!/bin/env ruby

SimpleCov.start 'rails' do
  add_filter '/db'
end
