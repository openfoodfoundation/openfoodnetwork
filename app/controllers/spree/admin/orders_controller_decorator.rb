require 'open_food_network/spree_api_key_loader'

Spree::Admin::OrdersController.class_eval do
  include OpenFoodNetwork::SpreeApiKeyLoader
  helper CheckoutHelper
  before_filter :load_spree_api_key, :only => :bulk_management
  before_filter :load_order, only: %i[show edit update fire resend invoice print open_adjustments close_adjustments]

  before_filter :load_distribution_choices, only: [:new, :edit, :update]

  # Ensure that the distributor is set for an order when
  before_filter :ensure_distribution, only: :new

  # After updating an order, the fees should be updated as well
  # Currently, adding or deleting line items does not trigger updating the
  # fees! This is a quick fix for that.
  # TODO: update fees when adding/removing line items
  # instead of the update_distribution_charge method.
  after_filter :update_distribution_charge, :only => :update

  before_filter :require_distributor_abn, only: :invoice


  respond_to :html, :json

  # Mostly the original Spree method, tweaked to allow us to ransack with completed_at in a sane way
  def index
    params[:q] ||= {}
    params[:q][:completed_at_not_null] ||= '1' if Spree::Config[:show_only_complete_orders_by_default]
    @show_only_completed = params[:q][:completed_at_not_null].present?
    params[:q][:s] ||= @show_only_completed ? 'completed_at desc' : 'created_at desc'

    # As date params are deleted if @show_only_completed, store
    # the original date so we can restore them into the params
    # after the search
    created_at_gt = params[:q][:created_at_gt]
    created_at_lt = params[:q][:created_at_lt]

    params[:q].delete(:inventory_units_shipment_id_null) if params[:q][:inventory_units_shipment_id_null] == "0"

    if !params[:q][:created_at_gt].blank?
      params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue ""
    end

    if !params[:q][:created_at_lt].blank?
      params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
    end

    # Changed this to stop completed_at being overriden when present
    if @show_only_completed
      params[:q][:completed_at_gt] = params[:q].delete(:created_at_gt) unless params[:q][:completed_at_gt]
      params[:q][:completed_at_lt] = params[:q].delete(:created_at_lt) unless params[:q][:completed_at_gt]
    end

    @orders = orders

    # Restore dates
    params[:q][:created_at_gt] = created_at_gt
    params[:q][:created_at_lt] = created_at_lt

    respond_with(@orders) do |format|
      format.html
      format.json do
        render_as_json @orders
      end
    end
  end

  # Overwrite to use confirm_email_for_customer instead of confirm_email.
  # This uses a new template. See mailers/spree/order_mailer_decorator.rb.
  def resend
    Spree::OrderMailer.confirm_email_for_customer(@order.id, true).deliver
    flash[:success] = t(:order_email_resent)

    respond_with(@order) { |format| format.html { redirect_to :back } }
  end

  def invoice
    template = if Spree::Config.invoice_style2? then "spree/admin/orders/invoice2" else "spree/admin/orders/invoice" end
    pdf = render_to_string pdf: "invoice-#{@order.number}.pdf", template: template, formats: [:html], encoding: "UTF-8"
    Spree::OrderMailer.invoice_email(@order.id, pdf).deliver
    flash[:success] = t('admin.orders.invoice_email_sent')

    respond_with(@order) { |format| format.html { redirect_to edit_admin_order_path(@order) } }
  end

  def print
    template = if Spree::Config.invoice_style2? then "spree/admin/orders/invoice2" else "spree/admin/orders/invoice" end
    render pdf: "invoice-#{@order.number}", template: template, encoding: "UTF-8"
  end

  def print_ticket
    render template: "spree/admin/orders/ticket", layout: false
  end

  def update_distribution_charge
    @order.update_distribution_charge!
  end

  private

  def orders
    if json_request?
      @search = OpenFoodNetwork::Permissions.new(spree_current_user).editable_orders.ransack(params[:q])
      @search.result.reorder('id ASC')
    else
      @search = Spree::Order.accessible_by(current_ability, :index).ransack(params[:q])

      # Replaced this search to filter orders to only show those distributed by current user (or all for admin user)
      @search.result.includes([:user, :shipments, :payments]).
        distributed_by_user(spree_current_user).
        page(params[:page]).
        per(params[:per_page] || Spree::Config[:orders_per_page])
    end
  end

  def require_distributor_abn
    unless @order.distributor.abn.present?
      flash[:error] = t(:must_have_valid_business_number, enterprise_name: @order.distributor.name)
      respond_with(@order) { |format| format.html { redirect_to edit_admin_order_path(@order) } }
    end
  end

  def load_distribution_choices
    @shops = Enterprise.is_distributor.managed_by(spree_current_user).by_name

    ocs = OrderCycle.managed_by(spree_current_user)
    @order_cycles = ocs.soonest_closing +
                    ocs.soonest_opening +
                    ocs.closed +
                    ocs.undated
  end

  def ensure_distribution
    unless @order
      @order = Spree::Order.new
      @order.generate_order_number
      @order.save!
    end
    unless @order.distribution_set?
      render 'set_distribution', locals: { order: @order }
    end
  end

end
