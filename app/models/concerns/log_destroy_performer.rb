# frozen_string_literal: true

require 'active_support/concern'

module LogDestroyPerformer
  extend ActiveSupport::Concern

  included do
    attr_accessor :destroyed_by

    after_destroy :log_who_destroyed

    def log_who_destroyed
      message = if destroyed_by.nil?
                  "#{self.class} #{id} deleted"
                else
                  "#{self.class} #{id} deleted by #{destroyed_by.id} <#{destroyed_by.email}>"
                end
      Rails.logger.info message
    end
  end
end
