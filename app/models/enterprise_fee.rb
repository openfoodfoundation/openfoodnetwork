class EnterpriseFee < ActiveRecord::Base
  belongs_to :enterprise

  calculated_adjustments

  attr_accessible :enterprise_id, :fee_type, :name, :calculator_type

  FEE_TYPES = %w(packing transport admin sales)
  PER_ORDER_CALCULATORS = ['Spree::Calculator::FlatRate', 'Spree::Calculator::FlexiRate']


  validates_inclusion_of :fee_type, :in => FEE_TYPES
  validates_presence_of :name


  scope :for_enterprise, lambda { |enterprise| where(enterprise_id: enterprise) }

  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      where('enterprise_id IN (?)', user.enterprises)
    end
  }

  scope :per_item, lambda {
    joins(:calculator).where('spree_calculators.type NOT IN (?)', PER_ORDER_CALCULATORS)
  }
  scope :per_order, lambda {
    joins(:calculator).where('spree_calculators.type IN (?)', PER_ORDER_CALCULATORS)
  }

  def self.clear_all_adjustments_for(line_item)
    line_item.order.adjustments.where(originator_type: 'EnterpriseFee', source_id: line_item, source_type: 'Spree::LineItem').destroy_all
  end

  def self.clear_all_adjustments_on_order(order)
    order.adjustments.where(originator_type: 'EnterpriseFee', source_type: 'Spree::LineItem').destroy_all
  end

  # Create an adjustment that starts as locked. Preferable to making an adjustment and locking it since
  # the unlocked adjustment tends to get hit by callbacks before we have a chance to lock it.
  def create_locked_adjustment(label, target, calculable, mandatory=false)
    amount = compute_amount(calculable)
    return if amount == 0 && !mandatory
    target.adjustments.create({ :amount => amount,
                                :source => calculable,
                                :originator => self,
                                :label => label,
                                :mandatory => mandatory,
                                :locked => true}, :without_protection => true)
  end
end
