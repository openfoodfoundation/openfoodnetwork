class EnterpriseFee < ActiveRecord::Base
  belongs_to :enterprise

  calculated_adjustments
  has_one   :calculator, :as => :calculable, :dependent => :destroy, :class_name => 'Spree::Calculator'

  attr_accessible :enterprise_id, :fee_type, :name, :calculator_type

  FEE_TYPES = %w(packing transport admin sales)

  validates_inclusion_of :fee_type, :in => FEE_TYPES
  validates_presence_of :name
end
