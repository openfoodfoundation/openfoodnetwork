# This class is a lightweight model used to validate preferences for business model configuration
# when they are submitted to the BusinessModelConfigurationController

module OpenFoodNetwork
  class BusinessModelConfigurationValidator
    include ActiveModel::Validations

    attr_accessor :account_invoices_monthly_fixed, :account_invoices_monthly_rate, :account_invoices_monthly_cap

    validates :account_invoices_monthly_fixed, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :account_invoices_monthly_rate, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
    validates :account_invoices_monthly_cap, presence: true, numericality: { greater_than_or_equal_to: 0 }

    def initialize(attr, button=nil)
      attr.each { |k,v| instance_variable_set("@#{k}", v) }
      @button = button
    end
  end
end
