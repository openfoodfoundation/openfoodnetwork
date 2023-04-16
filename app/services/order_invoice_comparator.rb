# frozen_string_literal: true

class OrderInvoiceComparator
  def can_generate_new_invoice?(current_state_invoice, latest_invoice)
    # We'll use a recursive BFS algorithm to find if the invoice is outdated
    # the root will be the order
    # On each node, we'll a list of relevant attributes that will be used on the comparison
    different?(current_state_invoice.presenter, latest_invoice.presenter,
               invoice_generation_selector)
  end

  def can_update_latest_invoice?(current_state_invoice, latest_invoice)
    different?(current_state_invoice.presenter, latest_invoice.presenter, invoice_update_selector)
  end

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
end
