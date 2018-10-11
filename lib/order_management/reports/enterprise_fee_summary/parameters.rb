require "open_food_network/reports/parameters/base"

module OrderManagement
  module Reports
    module EnterpriseFeeSummary
      class Parameters < OpenFoodNetwork::Reports::Parameters::Base
        @i18n_scope = "order_management.reports.enterprise_fee_summary"

        DATE_END_BEFORE_START_ERROR = I18n.t("date_end_before_start_error", scope: @i18n_scope)

        extend ActiveModel::Naming
        extend ActiveModel::Translation
        include ActiveModel::Validations

        attr_accessor :start_at, :end_at, :distributor_ids, :producer_ids, :order_cycle_ids,
                      :enterprise_fee_ids, :shipping_method_ids, :payment_method_ids

        validates :start_at, :end_at, date_time_string: true
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
        end

        protected

        def require_valid_datetime_range
          return if start_at.blank? || end_at.blank?

          errors.add(:end_at, DATE_END_BEFORE_START_ERROR) unless start_at < end_at
        end
      end
    end
  end
end
