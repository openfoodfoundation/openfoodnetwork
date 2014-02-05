class OrderCycle < ActiveRecord::Base
  belongs_to :coordinator, :class_name => 'Enterprise'
  has_and_belongs_to_many :coordinator_fees, :class_name => 'EnterpriseFee', :join_table => 'coordinator_fees'

  has_many :exchanges, :dependent => :destroy

  # TODO: DRY the incoming/outgoing clause used in several cases below
  # See Spree::Product definition, scopes variants and variants_including_master
  # This will require these accessors to be renamed
  attr_accessor :incoming_exchanges, :outgoing_exchanges

  validates_presence_of :name, :coordinator_id

  scope :active, lambda { where('order_cycles.orders_open_at <= ? AND order_cycles.orders_close_at >= ?', Time.now, Time.now) }
  scope :active_or_complete, lambda { where('order_cycles.orders_open_at <= ?', Time.now) }
  scope :inactive, lambda { where('order_cycles.orders_open_at > ? OR order_cycles.orders_close_at < ?', Time.now, Time.now) }
  scope :upcoming, lambda { where('order_cycles.orders_open_at > ?', Time.now) }
  scope :closed, lambda { where('order_cycles.orders_close_at < ?', Time.now) }
  scope :undated, where(orders_open_at: nil, orders_close_at: nil)

  scope :distributing_product, lambda { |product|
    joins(:exchanges => :variants).
    merge(Exchange.outgoing).
    where('spree_variants.id IN (?)', product.variants_including_master.map(&:id)).
    select('DISTINCT order_cycles.*') }

  scope :with_distributor, lambda { |distributor|
    joins(:exchanges).merge(Exchange.outgoing).where('exchanges.receiver_id = ?', distributor)
  }

  scope :soonest_closing,      lambda { active.order('order_cycles.orders_close_at ASC') }
  scope :most_recently_closed, lambda { closed.order('order_cycles.orders_close_at DESC') }
  scope :soonest_opening,      lambda { upcoming.order('order_cycles.orders_open_at ASC') }


  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      where('coordinator_id IN (?)', user.enterprises)
    end
  }

  # Order cycles that user coordinates, sends to or receives from
  scope :accessible_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      with_exchanging_enterprises_outer.
      where('order_cycles.coordinator_id IN (?) OR enterprises.id IN (?)', user.enterprises, user.enterprises).
      select('DISTINCT order_cycles.*')
    end
  }

  scope :with_exchanging_enterprises_outer, lambda {
    joins('LEFT OUTER JOIN exchanges ON (exchanges.order_cycle_id = order_cycles.id)').
    joins('LEFT OUTER JOIN enterprises ON (enterprises.id = exchanges.sender_id OR enterprises.id = exchanges.receiver_id)')
  }

  def self.first_opening_for(distributor)
    with_distributor(distributor).soonest_opening.first
  end

  def self.most_recently_closed_for(distributor)
    OrderCycle.with_distributor(distributor).most_recently_closed.first
  end

  def clone!
    oc = self.dup
    oc.name = "COPY OF #{oc.name}"
    oc.orders_open_at = oc.orders_close_at = nil
    oc.coordinator_fee_ids = self.coordinator_fee_ids
    oc.save!
    self.exchanges.each { |e| e.clone!(oc) }
    oc.reload
  end

  def suppliers
    self.exchanges.where(:receiver_id => self.coordinator).map(&:sender).uniq
  end

  def distributors
    self.exchanges.where(:sender_id => self.coordinator).map(&:receiver).uniq
  end

  def variants
    self.exchanges.map(&:variants).flatten.uniq
  end

  def distributed_variants
    self.exchanges.where(:sender_id => self.coordinator).map(&:variants).flatten.uniq
  end

  def variants_distributed_by(distributor)
    self.exchanges.where(:sender_id => self.coordinator, :receiver_id => distributor).
      map(&:variants).flatten.uniq
  end

  def products_distributed_by(distributor)
    variants_distributed_by(distributor).map(&:product).uniq
  end

  def products
    self.variants.map(&:product).uniq
  end

  def has_distributor?(distributor)
    self.distributors.include? distributor
  end

  def has_variant?(variant)
    self.variants.include? variant
  end

  def undated?
    self.orders_open_at.nil? && self.orders_close_at.nil?
  end

  def upcoming?
    self.orders_open_at && Time.now < self.orders_open_at
  end

  def open?
    self.orders_open_at && self.orders_close_at &&
      Time.now > self.orders_open_at && Time.now < self.orders_close_at
  end

  def closed?
    self.orders_close_at && Time.now > self.orders_close_at
  end

  def exchange_for_distributor(distributor)
    exchanges.outgoing.to_enterprises([distributor]).first
  end

  def pickup_time_for(distributor)
    exchange_for_distributor(distributor).andand.pickup_time || distributor.next_collection_at
  end

  def pickup_instructions_for(distributor)
    exchange_for_distributor(distributor).andand.pickup_instructions
  end


  # -- Fees
  def fees_for(variant, distributor)
    enterprise_fees_for(variant, distributor).sum do |fee|
      # Spree's Calculator interface accepts Orders or LineItems,
      # so we meet that interface with a struct.
      line_item = OpenStruct.new variant: variant, quantity: 1
      fee[:enterprise_fee].compute_amount(line_item)
    end
  end

  def create_adjustments_for(line_item)
    variant = line_item.variant
    distributor = line_item.order.distributor

    enterprise_fees_for(variant, distributor).each { |fee| create_adjustment_for_fee line_item, fee[:enterprise_fee], fee[:label], fee[:role] }
  end


  private

  # -- Fees
  def enterprise_fees_for(variant, distributor)
    fees = []

    exchanges_carrying(variant, distributor).each do |exchange|
      exchange.enterprise_fees.each do |enterprise_fee|
        role = exchange.incoming? ? 'supplier' : 'distributor'
        fees << {enterprise_fee: enterprise_fee,
                 label: adjustment_label_for(variant, enterprise_fee, role),
                 role: role}
      end
    end

    coordinator_fees.each do |enterprise_fee|
      fees << {enterprise_fee: enterprise_fee,
               label: adjustment_label_for(variant, enterprise_fee, 'coordinator'),
               role: 'coordinator'}
    end

    fees
  end

  def create_adjustment_for_fee(line_item, enterprise_fee, label, role)
    a = enterprise_fee.create_locked_adjustment(label, line_item.order, line_item, true)
    AdjustmentMetadata.create! adjustment: a, enterprise: enterprise_fee.enterprise, fee_name: enterprise_fee.name, fee_type: enterprise_fee.fee_type, enterprise_role: role
  end

  def adjustment_label_for(variant, enterprise_fee, role)
    "#{variant.product.name} - #{enterprise_fee.fee_type} fee by #{role} #{enterprise_fee.enterprise.name}"
  end

  def exchanges_carrying(variant, distributor)
    exchanges.to_enterprises([coordinator, distributor]).with_variant(variant)
  end
end
