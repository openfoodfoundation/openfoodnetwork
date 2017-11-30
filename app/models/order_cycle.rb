class OrderCycle < ActiveRecord::Base
  belongs_to :coordinator, :class_name => 'Enterprise'

  has_many :coordinator_fee_refs, class_name: 'CoordinatorFee'
  has_many :coordinator_fees, through: :coordinator_fee_refs, source: :enterprise_fee

  has_many :exchanges, :dependent => :destroy

  has_and_belongs_to_many :schedules, join_table: 'order_cycle_schedules'

  # TODO: DRY the incoming/outgoing clause used in several cases below
  # See Spree::Product definition, scopes variants and variants_including_master
  # This will require these accessors to be renamed
  attr_accessor :incoming_exchanges, :outgoing_exchanges

  validates_presence_of :name, :coordinator_id

  after_save :refresh_products_cache

  preference :product_selection_from_coordinator_inventory_only, :boolean, default: false

  scope :active, lambda { where('order_cycles.orders_open_at <= ? AND order_cycles.orders_close_at >= ?', Time.zone.now, Time.zone.now) }
  scope :active_or_complete, lambda { where('order_cycles.orders_open_at <= ?', Time.zone.now) }
  scope :inactive, lambda { where('order_cycles.orders_open_at > ? OR order_cycles.orders_close_at < ?', Time.zone.now, Time.zone.now) }
  scope :upcoming, lambda { where('order_cycles.orders_open_at > ?', Time.zone.now) }
  scope :not_closed, lambda { where('order_cycles.orders_close_at > ? OR order_cycles.orders_close_at IS NULL', Time.zone.now) }
  scope :closed, lambda { where('order_cycles.orders_close_at < ?', Time.zone.now).order("order_cycles.orders_close_at DESC") }
  scope :undated, where('order_cycles.orders_open_at IS NULL OR orders_close_at IS NULL')
  scope :dated, where('orders_open_at IS NOT NULL AND orders_close_at IS NOT NULL')

  scope :soonest_closing,      lambda { active.order('order_cycles.orders_close_at ASC') }
  # TODO This method returns all the closed orders. So maybe we can replace it with :recently_closed.
  scope :most_recently_closed, lambda { closed.order('order_cycles.orders_close_at DESC') }

  scope :soonest_opening,      lambda { upcoming.order('order_cycles.orders_open_at ASC') }

  scope :by_name, order('name')

  scope :distributing_product, lambda { |product|
    joins(:exchanges).
      merge(Exchange.outgoing).
      merge(Exchange.with_product(product)).
      select('DISTINCT order_cycles.*') }

  scope :with_distributor, lambda { |distributor|
    joins(:exchanges).merge(Exchange.outgoing).merge(Exchange.to_enterprise(distributor))
  }


  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      where('coordinator_id IN (?)', user.enterprises)
    end
  }

  # Return order cycles that user coordinates, sends to or receives from
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

  scope :involving_managed_distributors_of, lambda { |user|
    enterprises = Enterprise.managed_by(user)

    # Order cycles where I managed an enterprise at either end of an outgoing exchange
    # ie. coordinator or distibutor
    joins(:exchanges).merge(Exchange.outgoing).
      where('exchanges.receiver_id IN (?) OR exchanges.sender_id IN (?)', enterprises, enterprises).
      select('DISTINCT order_cycles.*')
  }

  scope :involving_managed_producers_of, lambda { |user|
    enterprises = Enterprise.managed_by(user)

    # Order cycles where I managed an enterprise at either end of an incoming exchange
    # ie. coordinator or producer
    joins(:exchanges).merge(Exchange.incoming).
      where('exchanges.receiver_id IN (?) OR exchanges.sender_id IN (?)', enterprises, enterprises).
      select('DISTINCT order_cycles.*')
  }

  def self.first_opening_for(distributor)
    with_distributor(distributor).soonest_opening.first
  end

  def self.first_closing_for(distributor)
    with_distributor(distributor).soonest_closing.first
  end

  def self.most_recently_closed_for(distributor)
    with_distributor(distributor).most_recently_closed.first
  end

  # Find the earliest closing times for each distributor in an active order cycle, and return
  # them in the format {distributor_id => closing_time, ...}
  def self.earliest_closing_times
    Hash[
      Exchange.
        outgoing.
        joins(:order_cycle).
        merge(OrderCycle.active).
        group('exchanges.receiver_id').
        select('exchanges.receiver_id AS receiver_id, MIN(order_cycles.orders_close_at) AS earliest_close_at').
        map { |ex| [ex.receiver_id, ex.earliest_close_at.to_time] }
    ]
  end

  def clone!
    oc = self.dup
    oc.name = "COPY OF #{oc.name}"
    oc.orders_open_at = oc.orders_close_at = nil
    oc.coordinator_fee_ids = self.coordinator_fee_ids
    oc.preferred_product_selection_from_coordinator_inventory_only = self.preferred_product_selection_from_coordinator_inventory_only
    oc.save!
    self.exchanges.each { |e| e.clone!(oc) }
    oc.reload
  end

  def suppliers
    enterprise_ids = self.exchanges.incoming.pluck :sender_id
    Enterprise.where('enterprises.id IN (?)', enterprise_ids)
  end

  def distributors
    enterprise_ids = self.exchanges.outgoing.pluck :receiver_id
    Enterprise.where('enterprises.id IN (?)', enterprise_ids)
  end

  def variants
    Spree::Variant.
      joins(:exchanges).
      merge(Exchange.in_order_cycle(self)).
      not_deleted.
      select('DISTINCT spree_variants.*').
      to_a # http://stackoverflow.com/q/15110166
  end

  def supplied_variants
    self.exchanges.incoming.map(&:variants).flatten.uniq.reject(&:deleted?)
  end

  def distributed_variants
    # TODO: only used in DistributionChangeValidator, can we remove?
    self.exchanges.outgoing.map(&:variants).flatten.uniq.reject(&:deleted?)
  end

  def variants_distributed_by(distributor)
    return Spree::Variant.where("1=0") unless distributor.present?
    Spree::Variant.
      not_deleted.
      merge(distributor.inventory_variants).
      joins(:exchanges).
      merge(Exchange.in_order_cycle(self)).
      merge(Exchange.outgoing).
      merge(Exchange.to_enterprise(distributor))
  end

  def products_distributed_by(distributor)
    variants_distributed_by(distributor).map(&:product).uniq
  end

  # If a product without variants is added to an order cycle, and then some variants are added
  # to that product, but not the order cycle, then the master variant should not available for customers
  # to purchase.
  # This method filters out such products so that the customer cannot purchase them.
  def valid_products_distributed_by(distributor)
    variants = variants_distributed_by(distributor)
    products = variants.map(&:product).uniq
    product_ids = products.reject{ |p| product_has_only_obsolete_master_in_distribution?(p, variants) }.map(&:id)
    Spree::Product.where(id: product_ids)
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

  def dated?
    !undated?
  end

  def undated?
    self.orders_open_at.nil? || self.orders_close_at.nil?
  end

  def upcoming?
    self.orders_open_at && Time.zone.now < self.orders_open_at
  end

  def open?
    self.orders_open_at && self.orders_close_at &&
      Time.zone.now > self.orders_open_at && Time.zone.now < self.orders_close_at
  end

  def closed?
    self.orders_close_at && Time.zone.now > self.orders_close_at
  end

  def exchange_for_distributor(distributor)
    exchanges.outgoing.to_enterprises([distributor]).first
  end

  def exchange_for_supplier(supplier)
    exchanges.incoming.from_enterprises([supplier]).first
  end

  def receival_instructions_for(supplier)
    exchange_for_supplier(supplier).andand.receival_instructions
  end

  def pickup_time_for(distributor)
    exchange_for_distributor(distributor).andand.pickup_time || distributor.next_collection_at
  end

  def pickup_instructions_for(distributor)
    exchange_for_distributor(distributor).andand.pickup_instructions
  end

  def exchanges_carrying(variant, distributor)
    exchanges.supplying_to(distributor).with_variant(variant)
  end

  def exchanges_supplying(order)
    exchanges.supplying_to(order.distributor).with_any_variant(order.variants)
  end

  def coordinated_by?(user)
    coordinator.users.include? user
  end

  def refresh_products_cache
    OpenFoodNetwork::ProductsCache.order_cycle_changed self
  end

  def items_bought_by_user(user, distributor)
    # The Spree::Order.complete scope only checks for completed_at date, does not ensure state is "complete"
    orders = Spree::Order.complete.where(state: "complete", user_id: user, distributor_id: distributor, order_cycle_id: self)
    scoper = OpenFoodNetwork::ScopeVariantToHub.new(distributor)
    items = Spree::LineItem.joins(:order).merge(orders)
    items.each { |li| scoper.scope(li.variant) }
  end

  private

  # If a product without variants is added to an order cycle, and then some variants are added
  # to that product, but not the order cycle, then the master variant should not available for customers
  # to purchase.
  # This method is used by #valid_products_distributed_by to filter out such products so that
  # the customer cannot purchase them.
  def product_has_only_obsolete_master_in_distribution?(product, distributed_variants)
    product.has_variants? &&
      distributed_variants.include?(product.master) &&
      (product.variants & distributed_variants).empty?
  end
end
