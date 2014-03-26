require 'open_food_network/enterprise_fee_applicator'

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
    where('spree_variants.id IN (?)', product.variants_including_master.pluck(:id)).
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
    self.exchanges.incoming.map(&:sender).uniq
  end

  def distributors
    self.exchanges.outgoing.map(&:receiver).uniq
  end

  def variants
    self.exchanges.map(&:variants).flatten.uniq
  end

  def distributed_variants
    self.exchanges.outgoing.map(&:variants).flatten.uniq
  end

  def variants_distributed_by(distributor)
    Spree::Variant.
      joins(:exchanges).
      merge(Exchange.outgoing).
      where('exchanges.order_cycle_id = ?', self).
      where('exchanges.receiver_id = ?', distributor)
  end

  def products_distributed_by(distributor)
    variants_distributed_by(distributor).map(&:product).uniq
  end

  # If a product without variants is added to an order cycle, and then some variants are added
  # to that product, then the master variant is still part of the order cycle, but customers
  # should not be able to purchase it.
  # This method filters out such products so that the customer cannot purchase them.
  def valid_products_distributed_by(distributor)
    variants = variants_distributed_by(distributor)
    products = variants.map(&:product).uniq
    products.reject { |p| product_has_only_obsolete_master_in_distribution?(p, variants) }
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

  # TODO: The boundary of this class is ill-defined here. OrderCycle should not know about
  # EnterpriseFeeApplicator. Clients should be able to query it for relevant EnterpriseFees.
  # This logic would fit better in another service object.

  def fees_for(variant, distributor)
    per_item_enterprise_fee_applicators_for(variant, distributor).sum do |applicator|
      # Spree's Calculator interface accepts Orders or LineItems,
      # so we meet that interface with a struct.
      # Amount is faked, this is a method on LineItem
      line_item = OpenStruct.new variant: variant, quantity: 1, amount: variant.price
      applicator.enterprise_fee.compute_amount(line_item)
    end
  end

  def create_line_item_adjustments_for(line_item)
    variant = line_item.variant
    distributor = line_item.order.distributor

    per_item_enterprise_fee_applicators_for(variant, distributor).each do |applicator|
      applicator.create_line_item_adjustment(line_item)
    end
  end

  def create_order_adjustments_for(order)
    per_order_enterprise_fee_applicators_for(order).each do |applicator|
      applicator.create_order_adjustment(order)
    end
  end


  private

  # -- Fees
  def per_item_enterprise_fee_applicators_for(variant, distributor)
    fees = []

    exchanges_carrying(variant, distributor).each do |exchange|
      exchange.enterprise_fees.per_item.each do |enterprise_fee|
        fees << OpenFoodNetwork::EnterpriseFeeApplicator.new(enterprise_fee, variant, exchange.role)
      end
    end

    coordinator_fees.per_item.each do |enterprise_fee|
      fees << OpenFoodNetwork::EnterpriseFeeApplicator.new(enterprise_fee, variant, 'coordinator')
    end

    fees
  end

  def per_order_enterprise_fee_applicators_for(order)
    fees = []

    exchanges_supplying(order).each do |exchange|
      exchange.enterprise_fees.per_order.each do |enterprise_fee|
        fees << OpenFoodNetwork::EnterpriseFeeApplicator.new(enterprise_fee, nil, exchange.role)
      end
    end

    coordinator_fees.per_order.each do |enterprise_fee|
      fees << OpenFoodNetwork::EnterpriseFeeApplicator.new(enterprise_fee, nil, 'coordinator')
    end

    fees
  end


  # -- Misc

  # If a product without variants is added to an order cycle, and then some variants are added
  # to that product, then the master variant is still part of the order cycle, but customers
  # should not be able to purchase it.
  # This method is used by #valid_products_distributed_by to filter out such products so that
  # the customer cannot purchase them.
  def product_has_only_obsolete_master_in_distribution?(product, distributed_variants)
    product.has_variants? &&
      distributed_variants.include?(product.master) &&
      (product.variants & distributed_variants).empty?
  end

  def exchanges_carrying(variant, distributor)
    exchanges.supplying_to(distributor).with_variant(variant)
  end

  def exchanges_supplying(order)
    exchanges.supplying_to(order.distributor).with_any_variant(order.variants)
  end
end
