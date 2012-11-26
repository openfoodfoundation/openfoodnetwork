class Exchange < ActiveRecord::Base
  belongs_to :order_cycle
  belongs_to :sender, :class_name => 'Enterprise'
  belongs_to :receiver, :class_name => 'Enterprise'
  belongs_to :payment_enterprise, :class_name => 'Enterprise'

  has_many :exchange_variants
  has_many :variants, :through => :exchange_variants

  has_many :exchange_fees
  has_many :enterprise_fees, :through => :exchange_fees

  validates_presence_of :order_cycle, :sender, :receiver
end
