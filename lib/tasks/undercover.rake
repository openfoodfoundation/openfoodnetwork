# frozen_string_literal: true

require 'simplecov'
require 'simplecov-lcov'
require 'undercover'

namespace :undercover do
  desc "Runs undercover comparison against master"
  task run_diff_master: :environment do
    "bundle exec undercover --compare origin/master"
  end
end
