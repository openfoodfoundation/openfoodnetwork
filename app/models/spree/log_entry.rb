# frozen_string_literal: true

module Spree
  class LogEntry < ApplicationRecord
    self.belongs_to_required_by_default = false

    belongs_to :source, polymorphic: true

    # Fix for Spree #1767
    # If a payment fails, we want to make sure we keep the record of it failing
    after_rollback :save_anyway

    def save_anyway
      log = Spree::LogEntry.new
      log.source  = source
      log.details = details
      log.save!
    end
  end
end
