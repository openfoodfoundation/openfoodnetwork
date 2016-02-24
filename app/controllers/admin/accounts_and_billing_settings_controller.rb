require 'open_food_network/accounts_and_billing_settings_validator'

class Admin::AccountsAndBillingSettingsController < Spree::Admin::BaseController
  before_filter :load_distributors, only: [:edit, :update, :start_job]
  before_filter :load_jobs, only: [:edit, :update, :start_job]
  before_filter :load_settings, only: [:edit, :update, :start_job]
  before_filter :require_valid_settings, only: [:update, :start_job]
  before_filter :require_known_job, only: [:start_job]

  def update
    Spree::Config.set(params[:settings])
    flash[:success] = t(:successfully_updated, :resource => t(:billing_and_account_settings))
    redirect_to_edit
  end

  def start_job
    if @update_account_invoices_job || @finalize_account_invoices_job
      flash[:error] = "A task is already running, please wait until it has finished"
    else
      new_job = "#{params[:job][:name]}".camelize.constantize.new
      Delayed::Job.enqueue new_job
      flash[:success] = "Task Queued"
    end

    redirect_to_edit
  end

  def show_methods
    @enterprise = Enterprise.find_by_id(params[:enterprise_id])
    @shipping_methods = @enterprise.shipping_methods
    @payment_methods = @enterprise.payment_methods
    render partial: 'method_settings'
  end

  private

  def redirect_to_edit
    redirect_to main_app.edit_admin_accounts_and_billing_settings_path
  end

  def require_valid_settings
    render :edit unless @settings.valid?
  end

  def known_jobs
    ['update_account_invoices', 'finalize_account_invoices']
  end

  def require_known_job
    unless known_jobs.include?(params[:job][:name])
      flash[:error] = "Unknown Task: #{params[:job][:name].to_s}"
      redirect_to_edit
    end
  end

  def load_settings
    @settings = OpenFoodNetwork::AccountsAndBillingSettingsValidator.new(params[:settings] || {
      accounts_distributor_id: Spree::Config[:accounts_distributor_id],
      default_accounts_payment_method_id: Spree::Config[:default_accounts_payment_method_id],
      default_accounts_shipping_method_id: Spree::Config[:default_accounts_shipping_method_id],
      auto_update_invoices: Spree::Config[:auto_update_invoices],
      auto_finalize_invoices: Spree::Config[:auto_finalize_invoices]
    })
  end

  def load_distributors
    @distributors = Enterprise.is_distributor.select([:id, :name])
  end

  def load_jobs
    @update_account_invoices_job = Delayed::Job.where("handler LIKE (?)", "%UpdateAccountInvoices%").last
    @finalize_account_invoices_job = Delayed::Job.where("handler LIKE (?)", "%FinalizeAccountInvoices%").last
  end
end
