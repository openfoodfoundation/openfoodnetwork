# frozen_string_literal: true

require "tasks/translations/transifex_updater"

namespace :ofn do
  namespace :translations do
    desc "Pull new translations from Transifex"

    task update: :environment do
      TransifexUpdater.new.update
    end
  end
end
