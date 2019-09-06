require 'open_food_network/spree_api_key_loader'

Spree::Admin::OrdersController.class_eval do
  include OpenFoodNetwork::SpreeApiKeyLoader
  helper CheckoutHelper
  before_filter :load_order, only: %i[show edit update fire resend invoice print print_ticket]

  before_filter :load_distribution_choices, only: [:new, :edit, :update]

  # Ensure that the distributor is set for an order when
  before_filter :ensure_distribution, only: :new

  # After updating an order, the fees should be updated as well
  # Currently, adding or deleting line items does not trigger updating the
  # fees! This is a quick fix for that.
  # TODO: update fees when adding/removing line items
  # instead of the update_distribution_charge method.
  after_filter :update_distribution_charge, only: :update

  before_filter :require_distributor_abn, only: :invoice

  respond_to :html, :json

  def index
    # Overriding the action so we only render the page template. An angular request
    # within the page then fetches the data it needs from Api::OrdersController
  end

  def bulk_management
    load_spree_api_key
  end

  def edit
    @order.shipments.map &:refresh_rates

    AdvanceOrderService.new(@order).call

    # The payment step shows an error of 'No pending payments'
    # Clearing the errors from the order object will stop this error
    # appearing on the edit page where we don't want it to.
    @order.errors.clear
  end

  # Re-implement spree method so that it redirects to edit instead of rendering edit
  #   This allows page reloads while adding variants to the order (/edit), without being redirected to customer details page (/update)
  def update
    unless @order.update_attributes(params[:order]) && @order.line_items.present?
      @order.errors.add(:line_items, Spree.t('errors.messages.blank')) if @order.line_items.empty?
      return redirect_to edit_admin_order_path(@order), flash: { error: @order.errors.full_messages.join(', ') }
    end

    @order.update!
    if @order.complete?
      redirect_to edit_admin_order_path(@order)
    else
      # Jump to next step if order is not complete
      redirect_to admin_order_customer_path(@order)
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
    pdf = InvoiceRenderer.new.render_to_string(@order)

    Spree::OrderMailer.invoice_email(@order.id, pdf).deliver
    flash[:success] = t('admin.orders.invoice_email_sent')

    respond_with(@order) { |format| format.html { redirect_to edit_admin_order_path(@order) } }
  end

  def print
    render InvoiceRenderer.new.args(@order)
  end

  def print_ticket
    render template: "spree/admin/orders/ticket", layout: false
  end

  def update_distribution_charge
    @order.update_distribution_charge!
  end

  private

  def require_distributor_abn
    if @order.distributor.abn.blank?
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
