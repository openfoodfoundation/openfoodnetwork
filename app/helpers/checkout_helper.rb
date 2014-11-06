module CheckoutHelper
  def checkout_adjustments_for_summary(order, opts={})
    adjustments = order.adjustments.eligible
    exclude = opts[:exclude] || {}

    # Remove empty tax adjustments and (optionally) shipping fees
    adjustments.reject! { |a| a.originator_type == 'Spree::TaxRate' && a.amount == 0 }
    adjustments.reject! { |a| a.originator_type == 'Spree::ShippingMethod' } if exclude.include? :shipping

    enterprise_fee_adjustments = adjustments.select { |a| a.originator_type == 'EnterpriseFee' }
    adjustments.reject! { |a| a.originator_type == 'EnterpriseFee' }
    unless exclude.include? :distribution
      adjustments << Spree::Adjustment.new(label: 'Distribution', amount: enterprise_fee_adjustments.sum(&:amount))
    end

    adjustments
  end

  def checkout_adjustments_total(order)
    adjustments = checkout_adjustments_for_summary(order, exclude: [:shipping])
    adjustments.sum &:display_amount
  end

  def checkout_cart_total_with_adjustments(order)
    order.display_item_total.money.to_f + checkout_adjustments_total(order).money.to_f
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
