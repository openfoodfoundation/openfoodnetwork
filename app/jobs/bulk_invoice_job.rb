# frozen_string_literal: true

class BulkInvoiceJob < ApplicationJob
  include CableReady::Broadcaster
  delegate :render, to: ActionController::Base
  attr_reader :options

  def perform(order_ids, filepath, options = {})
    @options = options

    orders = Spree::Order.where(id: order_ids)

    if OpenFoodNetwork::FeatureToggle.enabled?(:invoices, current_user)
      orders = orders.invoiceable
    end

    orders = sort_orders(orders, order_ids)
    orders.each(&method(:generate_invoice))

    ensure_directory_exists filepath

    pdf.save filepath

    broadcast(filepath, options[:channel]) if options[:channel]
  end

  private

  # Ensures the records are returned in the same order the ids were originally given in
  def sort_orders(orders, order_ids)
    orders_by_id = orders.to_a.index_by(&:id)
    order_ids.map { |id| orders_by_id[id.to_i] }.compact
  end

  def renderer
    @renderer ||= InvoiceRenderer.new
  end

  def generate_invoice(order)
    renderer_data = if OpenFoodNetwork::FeatureToggle.enabled?(:invoices, current_user)
                      Orders::GenerateInvoiceService.new(order).generate_or_update_latest_invoice
                      order.invoices.first.presenter
                    else
                      order
                    end
    invoice = renderer.render_to_string(renderer_data, current_user)
    pdf << CombinePDF.parse(invoice)
  end

  def broadcast(filepath, channel)
    file_id = filepath.split("/").last.split(".").first

    cable_ready[channel].
      inner_html(
        selector: "#bulk_invoices_modal .modal-content",
        html: render(partial: "spree/admin/orders/bulk/invoice_link",
                     locals: { invoice_url: "/admin/orders/invoices/#{file_id}" })
      ).
      broadcast
  end

  def ensure_directory_exists(filepath)
    FileUtils.mkdir_p(File.dirname(filepath))
  end

  def pdf
    @pdf ||= CombinePDF.new
  end

  def current_user
    return unless options[:current_user_id]

    @current_user ||= Spree::User.find(options[:current_user_id])
  end
end
