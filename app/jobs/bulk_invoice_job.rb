# frozen_string_literal: true

class BulkInvoiceJob < ApplicationJob
  include CableReady::Broadcaster
  delegate :render, to: ActionController::Base

  def perform(order_ids, filepath, options = {})
    orders = sorted_orders(order_ids)
    orders.filter!(&:invoiceable?) if OpenFoodNetwork::FeatureToggle.enabled?(:invoices)
    orders.each(&method(:generate_invoice))

    ensure_directory_exists filepath

    pdf.save filepath

    broadcast(filepath, options[:channel]) if options[:channel]
  end

  private

  # Ensures the records are returned in the same order the ids were originally given in
  def sorted_orders(order_ids)
    orders_by_id = Spree::Order.where(id: order_ids).to_a.index_by(&:id)
    order_ids.map { |id| orders_by_id[id.to_i] }
  end

  def renderer
    @renderer ||= InvoiceRenderer.new
  end

  def generate_invoice(order)
    renderer_data = if OpenFoodNetwork::FeatureToggle.enabled?(:invoices)
                      OrderInvoiceGenerator.new(order).generate_or_update_latest_invoice
                      order.invoices.first.presenter
                    else
                      order
                    end
    invoice = renderer.render_to_string(renderer_data)
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
end
