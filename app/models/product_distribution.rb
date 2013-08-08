class ProductDistribution < ActiveRecord::Base
  belongs_to :product, :class_name => 'Spree::Product'
  belongs_to :distributor, :class_name => 'Enterprise'
  belongs_to :shipping_method, :class_name => 'Spree::ShippingMethod'
  belongs_to :enterprise_fee

  validates_presence_of :product_id, :on => :update
  validates_presence_of :distributor_id, :shipping_method_id
  validates_uniqueness_of :product_id, :scope => :distributor_id


  def ensure_correct_adjustment_for(line_item)
    if enterprise_fee
      clear_all_enterprise_fee_adjustments_on line_item
      create_adjustment_on line_item
    end
  end

  def adjustment_on(line_item)
    adjustments = line_item.adjustments.where(originator_id: enterprise_fee)

    raise "Multiple adjustments for this enterprise fee on this line item. This method is not designed to deal with this scenario." if adjustments.count > 1

    adjustments.first
  end

  def create_adjustment_on(line_item)
    enterprise_fee.create_adjustment(adjustment_label, line_item, line_item, true)
  end

  def clear_all_enterprise_fee_adjustments_on(line_item)
    line_item.adjustments.where(originator_type: 'EnterpriseFee').destroy_all
  end

  def adjustment_label
    "Product distribution by #{distributor.name}"
  end

end
