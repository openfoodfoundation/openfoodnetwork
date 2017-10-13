class ProductDistribution < ActiveRecord::Base
  belongs_to :product, :class_name => 'Spree::Product'
  belongs_to :distributor, :class_name => 'Enterprise'
  belongs_to :enterprise_fee

  validates_presence_of :product_id, :on => :update
  validates_presence_of :distributor_id, :enterprise_fee_id
  validates_uniqueness_of :product_id, :scope => :distributor_id


  def adjustment_for(line_item)
    adjustments = line_item.order.adjustments.enterprise_fee.where(originator_id: enterprise_fee)

    raise "Multiple adjustments for this enterprise fee on this line item. This method is not designed to deal with this scenario." if adjustments.count > 1

    adjustments.first
  end

  def create_adjustment_for(line_item)
    a = enterprise_fee.create_adjustment(adjustment_label_for(line_item), line_item.order, line_item, true)
    AdjustmentMetadata.create! adjustment: a, enterprise: enterprise_fee.enterprise, fee_name: enterprise_fee.name, fee_type: enterprise_fee.fee_type, enterprise_role: 'distributor'
  end

  def adjustment_label_for(line_item)
    I18n.t(:products_distribution_adjustment_label, distributor: distributor.name, product: line_item.product.name )
  end
end
