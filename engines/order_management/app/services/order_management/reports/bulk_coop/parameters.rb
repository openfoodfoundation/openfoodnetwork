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
        validates_inclusion_of :report_type, in: OrderManagement::Reports::BulkCoop::BulkCoopReport::REPORT_TYPES.map(&:to_s)

        validate :require_valid_datetime_range

        def self.date_end_before_start_error_message
          i18n_scope = "order_management.reports.enterprise_fee_summary"
          I18n.t("date_end_before_start_error", scope: i18n_scope)
        end

        def initialize(attributes = {})
          self.distributor_ids = []

          super(attributes)
        end

        def authorize!(permissions)
          authorizer = Authorizer.new(self, permissions)
          authorizer.authorize!
        end

        protected

        def require_valid_datetime_range
          return if start_at.blank? || end_at.blank?

          error_message = self.class.date_end_before_start_error_message
          errors.add(:end_at, error_message) unless start_at < end_at
        end

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
