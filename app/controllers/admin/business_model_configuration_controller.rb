require 'open_food_network/business_model_configuration_validator'

class Admin::BusinessModelConfigurationController < Spree::Admin::BaseController
  before_filter :load_settings, only: [:edit, :update]
  before_filter :require_valid_settings, only: [:update]

  def update
    Spree::Config.set(params[:settings])
    flash[:success] = t(:successfully_updated,
                        resource: t('admin.business_model_configuration.edit.business_model_configuration'))
    redirect_to_edit
  end

  private

  def redirect_to_edit
    redirect_to main_app.edit_admin_business_model_configuration_path
  end

  def load_settings
    @settings = OpenFoodNetwork::BusinessModelConfigurationValidator.new(params[:settings] || {
      shop_trial_length_days: Spree::Config[:shop_trial_length_days],
      account_invoices_monthly_fixed: Spree::Config[:account_invoices_monthly_fixed],
      account_invoices_monthly_rate: Spree::Config[:account_invoices_monthly_rate],
      account_invoices_monthly_cap: Spree::Config[:account_invoices_monthly_cap],
      account_invoices_tax_rate: Spree::Config[:account_invoices_tax_rate],
      minimum_billable_turnover: Spree::Config[:minimum_billable_turnover]

    })
  end

  def require_valid_settings
    render :edit unless @settings.valid?
  end
end
