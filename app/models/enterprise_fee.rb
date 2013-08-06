class EnterpriseFee < ActiveRecord::Base
  belongs_to :enterprise

  calculated_adjustments

  attr_accessible :enterprise_id, :fee_type, :name, :calculator_type

  FEE_TYPES = %w(packing transport admin sales)

  validates_inclusion_of :fee_type, :in => FEE_TYPES
  validates_presence_of :name
end
