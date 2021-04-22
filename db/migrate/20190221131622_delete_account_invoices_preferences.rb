class DeleteAccountInvoicesPreferences < ActiveRecord::Migration[4.2]
  def up
    Spree::Preference
      .where( key: ['spree/app_configuration/accounts_distributor_id',
                    'spree/app_configuration/default_accounts_payment_method_id',
                    'spree/app_configuration/default_accounts_shipping_method_id',
                    'spree/app_configuration/auto_update_invoices',
                    'spree/app_configuration/auto_finalize_invoices',
                    'spree/app_configuration/account_invoices_monthly_fixed',
                    'spree/app_configuration/account_invoices_monthly_rate',
                    'spree/app_configuration/account_invoices_monthly_cap',
                    'spree/app_configuration/account_invoices_tax_rate',
                    'spree/app_configuration/shop_trial_length_days',
                    'spree/app_configuration/minimum_billable_turnover'])
      .destroy_all
  end

  def down
    # If these preferences are re-added to app/models/spree/app_configuration_decorator.rb
    #   these DB entries will be regenerated
  end
end
