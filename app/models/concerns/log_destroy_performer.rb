# frozen_string_literal: true

require 'active_support/concern'

module LogDestroyPerformer
  extend ActiveSupport::Concern
  included do
    attr_accessor :destroyed_by
    after_destroy :log_who_destroyed

    def log_who_destroyed
      return if destroyed_by.nil?

      Rails.logger.info "#{self.class} #{id} deleted by #{destroyed_by.id}"
    end
  end
end
