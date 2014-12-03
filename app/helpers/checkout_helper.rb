module CheckoutHelper
  def checkout_adjustments_for(order, opts={})
    adjustments = order.adjustments.eligible
    exclude = opts[:exclude] || {}

    # Remove empty tax adjustments and (optionally) shipping fees
    adjustments.reject! { |a| a.originator_type == 'Spree::TaxRate' && a.amount == 0 }
    adjustments.reject! { |a| a.originator_type == 'Spree::ShippingMethod' } if exclude.include? :shipping
    adjustments.reject! { |a| a.source_type == 'Spree::LineItem' } if exclude.include? :line_item

    enterprise_fee_adjustments = adjustments.select { |a| a.originator_type == 'EnterpriseFee' && a.source_type != 'Spree::LineItem' }
    adjustments.reject! { |a| a.originator_type == 'EnterpriseFee' && a.source_type != 'Spree::LineItem' }
    unless exclude.include? :admin_and_handling
      adjustments << Spree::Adjustment.new(label: 'Admin & Handling', amount: enterprise_fee_adjustments.sum(&:amount))
    end

    adjustments
  end

  def display_checkout_admin_and_handling_adjustments_total_for(order)
    adjustments = order.adjustments.eligible.where('originator_type = ? AND source_type != ? ', 'EnterpriseFee',  'Spree::LineItem' )
    Spree::Money.new( adjustments.sum( &:amount ) , { :currency => order.currency })
  end

  def checkout_line_item_adjustments(order)
    order.adjustments.eligible.where( source_type: "Spree::LineItem")
  end

  def checkout_subtotal(order)
    order.item_total + checkout_line_item_adjustments(order).sum( &:amount )
  end

  def display_checkout_subtotal(order)
    Spree::Money.new( checkout_subtotal(order) , { :currency => order.currency })
  end

  def checkout_state_options(source_address)
    if source_address == :billing
      address = @order.billing_address
    elsif source_address == :shipping
      address = @order.shipping_address
    end

    [[]] + address.country.states.map { |c| [c.name, c.id] }
  end

  def checkout_country_options
    available_countries.map { |c| [c.name, c.id] }
  end


  def validated_input(name, path, args = {})
    attributes = {
      required: true,
      type: :text,
      name: path,
      id: path,
      "ng-model" => path,
      "ng-class" => "{error: !fieldValid('#{path}')}"
    }.merge args

    render "shared/validated_input", name: name, path: path, attributes: attributes
  end

  def validated_select(name, path, options, args = {})
    attributes = {
      required: true,
      id: path,
      "ng-model" => path,
      "ng-class" => "{error: !fieldValid('#{path}')}"
    }.merge args

    render "shared/validated_select", name: name, path: path, options: options, attributes: attributes
  end

  def reset_order
    distributor = current_order.distributor
    token = current_order.token

    session[:order_id] = nil
    @current_order = nil
    current_order(true)

    current_order.set_distributor!(distributor)
    current_order.tokenized_permission.token = token
    current_order.tokenized_permission.save!
    session[:access_token] = token
  end
end
