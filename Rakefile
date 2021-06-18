#!/usr/bin/env rake
# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Openfoodnetwork::Application.load_tasks

if !ENV['DISABLE_KNAPSACK'] && defined?(Knapsack)
  Knapsack.load_tasks
end
