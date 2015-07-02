require 'open_food_network/accounts_and_billing_settings'

class Admin::AccountsAndBillingSettingsController < Spree::Admin::BaseController
  before_filter :load_distributors, only: [:edit, :update]

  def edit
    @settings = OpenFoodNetwork::AccountsAndBillingSettings.new({
      accounts_distributor_id: Spree::Config[:accounts_distributor_id],
      default_accounts_payment_method_id: Spree::Config[:default_accounts_payment_method_id],
      default_accounts_shipping_method_id: Spree::Config[:default_accounts_shipping_method_id],
      collect_billing_information: Spree::Config[:collect_billing_information],
      create_invoices_for_enterprise_users: Spree::Config[:create_invoices_for_enterprise_users]
    })
  end

  def update
    @settings = OpenFoodNetwork::AccountsAndBillingSettings.new(params[:settings])
    if @settings.valid?
      Spree::Config.set(params[:settings])
      flash[:success] = t(:successfully_updated, :resource => t(:billing_and_account_settings))
      redirect_to main_app.edit_admin_accounts_and_billing_settings_path
    else
      render :edit
    end
  end

  def show_methods
    @enterprise = Enterprise.find_by_id(params[:enterprise_id])
    @shipping_methods = @enterprise.shipping_methods
    @payment_methods = @enterprise.payment_methods
    render partial: 'method_settings'
  end

  private

  def load_distributors
    @distributors = Enterprise.is_distributor.select([:id, :name])
  end
end
