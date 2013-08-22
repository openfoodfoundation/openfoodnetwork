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
  scope :from_enterprises, lambda { |enterprises| where('exchanges.sender_id IN (?)', enterprises) }
  scope :to_enterprises, lambda { |enterprises| where('exchanges.receiver_id IN (?)', enterprises) }
  scope :with_variant, lambda { |variant| joins(:exchange_variants).where('exchange_variants.variant_id = ?', variant) }

  def clone!(new_order_cycle)
    exchange = self.dup
    exchange.order_cycle = new_order_cycle
    exchange.enterprise_fee_ids = self.enterprise_fee_ids
    exchange.variant_ids = self.variant_ids
    exchange.save!
    exchange
  end

  def incoming?
    receiver == order_cycle.coordinator
  end

  def to_h(core=false)
    h = attributes.merge({ 'variant_ids' => variant_ids, 'enterprise_fee_ids' => enterprise_fee_ids })
    h.reject! { |k| %w(id order_cycle_id created_at updated_at).include? k } if core
    h
  end

  def eql?(e)
    if e.respond_to? :to_h
      self.to_h(true) == e.to_h(true)
    else
      super e
    end
  end


end
