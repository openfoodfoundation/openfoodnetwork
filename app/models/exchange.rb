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

  accepts_nested_attributes_for :variants

  scope :incoming, joins(:order_cycle).where('exchanges.receiver_id = order_cycles.coordinator_id')
  scope :outgoing, joins(:order_cycle).where('exchanges.sender_id   = order_cycles.coordinator_id')
  scope :with_variant, lambda { |variant| joins(:exchange_variants).where('exchange_variants.variant_id = ?', variant) }
end
