require 'open_food_network/spree_api_key_loader'
require 'combine_pdf'

Spree::Admin::OrdersController.class_eval do
  include OpenFoodNetwork::SpreeApiKeyLoader
  helper CheckoutHelper
  before_filter :load_spree_api_key, :only => :bulk_management
  before_filter :load_order, only: %i[show edit update fire resend invoice print print_ticket]

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

  def index
    # Overriding the action so we only render the page template. An angular request
    # within the page then fetches the data it needs from Api::OrdersController
  end

  # Overwrite to use confirm_email_for_customer instead of confirm_email.
  # This uses a new template. See mailers/spree/order_mailer_decorator.rb.
  def resend
    Spree::OrderMailer.confirm_email_for_customer(@order.id, true).deliver
    flash[:success] = t(:order_email_resent)

    respond_with(@order) { |format| format.html { redirect_to :back } }
  end

  def invoice
    pdf = render_to_string pdf: "invoice-#{@order.number}.pdf",
                           template: invoice_template,
                           formats: [:html], encoding: "UTF-8"

    Spree::OrderMailer.invoice_email(@order.id, pdf).deliver
    flash[:success] = t('admin.orders.invoice_email_sent')

    respond_with(@order) { |format| format.html { redirect_to edit_admin_order_path(@order) } }
  end

  def bulk_invoice
    orders = Spree::Order.where(id: params[:order_ids])

    combined_pdf = CombinePDF.new

    orders.each do |order|
      @order = order
      pdf_data = render_to_string pdf: "invoice-#{order.number}.pdf", template: invoice_template,
                                  formats: [:html], encoding: "UTF-8"

      combined_pdf << CombinePDF.parse(pdf_data)
    end

    send_data combined_pdf.to_pdf, filename: "invoices.pdf",
                                   type: "application/pdf", disposition: :inline
  end

  def print
    render pdf: "invoice-#{@order.number}", template: invoice_template, encoding: "UTF-8"
  end

  def print_ticket
    render template: "spree/admin/orders/ticket", layout: false
  end

  def update_distribution_charge
    @order.update_distribution_charge!
  end

  private

  def invoice_template
    Spree::Config.invoice_style2? ? "spree/admin/orders/invoice2" : "spree/admin/orders/invoice"
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
