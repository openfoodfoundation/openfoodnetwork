class Exchange < ActiveRecord::Base
  belongs_to :order_cycle
  belongs_to :sender, :class_name => 'Enterprise'
  belongs_to :receiver, :class_name => 'Enterprise'
  belongs_to :payment_enterprise, :class_name => 'Enterprise'

  has_many :exchange_variants, :dependent => :destroy
  has_many :variants, :through => :exchange_variants

  has_many :exchange_fees, :dependent => :destroy
  has_many :enterprise_fees, :through => :exchange_fees

  validates_presence_of :order_cycle, :sender, :receiver
  validates_uniqueness_of :sender_id,   :scope => [:order_cycle_id, :receiver_id]
end
