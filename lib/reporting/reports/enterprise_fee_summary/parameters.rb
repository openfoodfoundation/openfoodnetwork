# frozen_string_literal: true

module Reporting
  module Reports
    module EnterpriseFeeSummary
      class Parameters < Reporting::Reports::EnterpriseFeeSummary::Reports::Parameters::Base
        include ActiveModel::Validations

        attr_accessor :completed_at_gt, :completed_at_lt, :distributor_ids,
                      :producer_ids, :order_cycle_ids, :enterprise_fee_ids,
                      :shipping_method_ids, :payment_method_ids

        before_validation :cleanup_arrays

        validates :completed_at_gt, :completed_at_lt, date_time_string: true
        validates :distributor_ids, :producer_ids, integer_array: true
        validates :order_cycle_ids, integer_array: true
        validates :enterprise_fee_ids, integer_array: true
        validates :shipping_method_ids, :payment_method_ids, integer_array: true

        validate :require_valid_datetime_range

        def initialize(attributes = {})
          self.distributor_ids = []
          self.producer_ids = []
          self.order_cycle_ids = []
          self.enterprise_fee_ids = []
          self.shipping_method_ids = []
          self.payment_method_ids = []

          super(attributes)

          cleanup_arrays
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
          producer_ids.reject!(&:blank?)
          order_cycle_ids.reject!(&:blank?)
          enterprise_fee_ids.reject!(&:blank?)
          shipping_method_ids.reject!(&:blank?)
          payment_method_ids.reject!(&:blank?)
        end
      end
    end
  end
end
