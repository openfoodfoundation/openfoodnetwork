# frozen_string_literal: true

namespace :ofn do
  namespace :data do
    desc 'Remove transient data'
    task remove_transient_data: :environment do
      require 'tasks/data/remove_transient_data'
      RemoveTransientData.new.call
    end
  end
end
