class CreateEnterpriseFeeRecordsForProductDistributions < ActiveRecord::Migration

  class ProductDistribution < ActiveRecord::Base
    belongs_to :shipping_method, :class_name => 'Spree::ShippingMethod'
    belongs_to :distributor, :class_name => 'Enterprise'
    belongs_to :enterprise_fee
  end

  def up
    ProductDistribution.all.each do |pd|
      calculator = pd.shipping_method.calculator.dup
      calculator.save!

      ef = EnterpriseFee.new enterprise_id: pd.distributor.id, fee_type: 'packing', name: pd.shipping_method.name
      ef.calculator = calculator
      ef.save!

      pd.enterprise_fee = ef
      pd.save!
    end
  end

  def down
    ProductDistribution.update_all :enterprise_fee_id => nil
  end
end
