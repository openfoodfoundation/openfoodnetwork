# frozen_string_literal: true

class OrderInvoiceComparator
  attr_reader :order

  def initialize(order)
    @order = order
  end

  def can_generate_new_invoice?
    return true if invoices.empty?

    # We'll use a recursive BFS algorithm to find if the invoice is outdated
    # the root will be the order
    # On each node, we'll a list of relevant attributes that will be used on the comparison
    different?(current_state_invoice, latest_invoice, invoice_generation_selector)
  end

  def can_update_latest_invoice?
    return false if invoices.empty?

    different?(current_state_invoice, latest_invoice, invoice_update_selector)
  end

  private

  def different?(node1, node2, attributes_selector)
    simple_values1, presenters1 = attributes_selector.call(node1)
    simple_values2, presenters2 = attributes_selector.call(node2)
    return true if simple_values1 != simple_values2

    return true if presenters1.size != presenters2.size

    presenters1.zip(presenters2).any? do |presenter1, presenter2|
      different?(presenter1, presenter2, attributes_selector)
    end
  end

  def invoice_generation_selector
    values_selector(:invoice_generation_values)
  end

  def invoice_update_selector
    values_selector(:invoice_update_values)
  end

  def values_selector(attribute)
    proc do |node|
      return [[], []] unless node.respond_to?(attribute)

      grouped = node.public_send(attribute).group_by(&grouper)
      [grouped[:simple] || [], grouped[:presenters]&.flatten || []]
    end
  end

  def grouper
    proc do |value|
      if value.is_a?(Array) || value.class.to_s.starts_with?("Invoice::DataPresenter")
        :presenters
      else
        :simple
      end
    end
  end

  def current_state_invoice
    @current_state_invoice ||= Invoice.new(
      order: order,
      data: serialize_for_invoice,
      date: Time.zone.today,
      number: invoices.count + 1
    ).presenter
  end

  def invoices
    order.invoices
  end

  def latest_invoice
    @latest_invoice ||= invoices.first.presenter
  end

  def serialize_for_invoice
    InvoiceDataGenerator.new(order).serialize_for_invoice
  end
end
