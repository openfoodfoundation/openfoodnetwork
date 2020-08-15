# frozen_string_literal: true

require 'highline'
require 'tasks/data/remove_transient_data'

namespace :ofn do
  namespace :data do
    desc 'Remove transient data'
    task remove_transient_data: :environment do
      RemoveTransientData.new.call
    end
  end
end
