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
  validates_uniqueness_of :sender_id, :scope => [:order_cycle_id, :receiver_id, :incoming]

  accepts_nested_attributes_for :variants

  scope :in_order_cycle, lambda { |order_cycle| where(order_cycle_id: order_cycle) }
  scope :incoming, where(incoming: true)
  scope :outgoing, where(incoming: false)
  scope :from_enterprise, lambda { |enterprise| where(sender_id: enterprise) }
  scope :to_enterprise, lambda { |enterprise| where(receiver_id: enterprise) }
  scope :from_enterprises, lambda { |enterprises| where('exchanges.sender_id IN (?)', enterprises) }
  scope :to_enterprises, lambda { |enterprises| where('exchanges.receiver_id IN (?)', enterprises) }
  scope :supplying_to, lambda { |distributor| where('exchanges.incoming OR exchanges.receiver_id = ?', distributor) }
  scope :with_variant, lambda { |variant| joins(:exchange_variants).where('exchange_variants.variant_id = ?', variant) }
  scope :with_any_variant, lambda { |variants| joins(:exchange_variants).where('exchange_variants.variant_id IN (?)', variants).select('DISTINCT exchanges.*') }
  scope :with_product, lambda { |product| joins(:exchange_variants).where('exchange_variants.variant_id IN (?)', product.variants_including_master) }


  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      joins('LEFT JOIN enterprises senders ON senders.id = exchanges.sender_id').
        joins('LEFT JOIN enterprises receivers ON receivers.id = exchanges.receiver_id').
        joins('LEFT JOIN enterprise_roles sender_roles ON sender_roles.enterprise_id = senders.id').
        joins('LEFT JOIN enterprise_roles receiver_roles ON receiver_roles.enterprise_id = receivers.id').
        where('sender_roles.user_id = ? AND receiver_roles.user_id = ?', user.id, user.id)
    end
  }


  def clone!(new_order_cycle)
    exchange = self.dup
    exchange.order_cycle = new_order_cycle
    exchange.enterprise_fee_ids = self.enterprise_fee_ids
    exchange.variant_ids = self.variant_ids
    exchange.save!
    exchange
  end

  def role
    incoming? ? 'supplier' : 'distributor'
  end

  def participant
    incoming? ? sender : receiver
  end

  def to_h(core_only=false)
    h = attributes.merge({ 'variant_ids' => variant_ids.sort, 'enterprise_fee_ids' => enterprise_fee_ids.sort })
    h.reject! { |k| %w(id order_cycle_id created_at updated_at).include? k } if core_only
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
