# This class is a lightweight model used to validate preferences for accounts and billing settings
# when they are submitted to the AccountsAndBillingSettingsController

module OpenFoodNetwork
  class AccountsAndBillingSettingsValidator
    include ActiveModel::Validations

    attr_accessor :accounts_distributor_id, :default_accounts_payment_method_id, :default_accounts_shipping_method_id
    attr_accessor :auto_update_invoices, :auto_finalize_invoices

    validate :ensure_accounts_distributor_set
    validate :ensure_default_payment_method_set
    validate :ensure_default_shipping_method_set
    # validate :ensure_billing_info_collected, unless: lambda { create_invoices_for_enterprise_users == '0' }

    def initialize(attr, button=nil)
      attr.each { |k,v| instance_variable_set("@#{k}", v) }
      @button = button
    end

    def ensure_accounts_distributor_set
      unless Enterprise.find_by_id(accounts_distributor_id)
        errors.add(:accounts_distributor, I18n.t('admin.accounts_and_billing_settings.errors.accounts_distributor'))
      end
    end

    def ensure_default_payment_method_set
      unless Enterprise.find_by_id(accounts_distributor_id) &&
        Enterprise.find_by_id(accounts_distributor_id).payment_methods.find_by_id(default_accounts_payment_method_id)
        errors.add(:default_payment_method, I18n.t('admin.accounts_and_billing_settings.errors.default_payment_method'))
      end
    end

    def ensure_default_shipping_method_set
      unless Enterprise.find_by_id(accounts_distributor_id) &&
        Enterprise.find_by_id(accounts_distributor_id).shipping_methods.find_by_id(default_accounts_shipping_method_id)
        errors.add(:default_shipping_method, I18n.t('admin.accounts_and_billing_settings.errors.default_shipping_method'))
      end
    end
  end
end
