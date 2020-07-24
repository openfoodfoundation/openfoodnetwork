# frozen_string_literal: true

module OrderManagement
  module Reports
    module BulkCoop
      class Parameters < ::Reports::Parameters::Base
        extend ActiveModel::Naming
        extend ActiveModel::Translation
        include ActiveModel::Validations

        attr_accessor :start_at, :end_at, :distributor_ids, :report_type

        before_validation :cleanup_arrays

        validates :start_at, :end_at, date_time_string: true
        validates :distributor_ids, integer_array: true
        validates_inclusion_of :report_type, in: BulkCoopReport::REPORT_TYPES.map(&:to_s)

        validate :require_valid_datetime_range

        def initialize(attributes = {})
          self.distributor_ids = []

          super(attributes)
        end

        def authorize!(permissions)
          authorizer = Authorizer.new(self, permissions)
          authorizer.authorize!
        end

        protected

        # Remove the blank strings that Rails multiple selects add by default to
        # make sure that blank lists are still submitted to the server as arrays
        # instead of nil.
        #
        # https://api.rubyonrails.org/classes/ActionView/Helpers/FormOptionsHelper.html#method-i-select
        def cleanup_arrays
          distributor_ids.reject!(&:blank?)
        end
      end
    end
  end
end
