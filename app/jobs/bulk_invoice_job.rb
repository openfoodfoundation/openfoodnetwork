# frozen_string_literal: true

class BulkInvoiceJob < ApplicationJob
  attr_reader :options

  def perform(order_ids, filepath, options = {})
    @options = options

    # The `find` method returns records in the same order as the given ids.
    orders = Spree::Order.find(order_ids)

    orders.each(&method(:generate_invoice))

    ensure_directory_exists filepath

    pdf.save filepath
  end

  private

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
