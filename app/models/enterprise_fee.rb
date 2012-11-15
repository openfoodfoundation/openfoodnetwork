class EnterpriseFee < ActiveRecord::Base
  belongs_to :enterprise

  FEE_TYPES = %w(Packing Transport Admin Sales)

  validates_inclusion_of :fee_type, :in => FEE_TYPES
  validates_presence_of :name
end
