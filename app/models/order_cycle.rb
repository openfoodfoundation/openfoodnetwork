# frozen_string_literal: true

require 'open_food_network/scope_variant_to_hub'

class OrderCycle < ApplicationRecord
  self.belongs_to_required_by_default = false

  searchable_attributes :orders_open_at, :orders_close_at, :coordinator_id
  searchable_scopes :active, :inactive, :active_or_complete, :upcoming, :closed, :not_closed,
                    :dated, :undated, :soonest_opening, :soonest_closing, :most_recently_closed

  belongs_to :coordinator, class_name: 'Enterprise'

  has_many :coordinator_fee_refs, class_name: 'CoordinatorFee'
  has_many :coordinator_fees, through: :coordinator_fee_refs, source: :enterprise_fee,
                              dependent: :destroy

  has_many :exchanges, dependent: :destroy

  # These scope names are prepended with "cached_" because there are existing accessor methods
  # :incoming_exchanges and :outgoing_exchanges.
  has_many :cached_incoming_exchanges, -> { where incoming: true }, class_name: "Exchange"
  has_many :cached_outgoing_exchanges, -> { where incoming: false }, class_name: "Exchange"

  has_many :suppliers, -> { distinct }, source: :sender, through: :cached_incoming_exchanges
  has_many :distributors, -> { distinct }, source: :receiver, through: :cached_outgoing_exchanges
  has_many :order_cycle_schedules
  has_many :schedules, through: :order_cycle_schedules
  has_and_belongs_to_many :selected_distributor_payment_methods,
                          class_name: 'DistributorPaymentMethod',
                          join_table: 'order_cycles_distributor_payment_methods'
  has_and_belongs_to_many :selected_distributor_shipping_methods,
                          class_name: 'DistributorShippingMethod',
                          join_table: 'order_cycles_distributor_shipping_methods'
  has_paper_trail meta: { custom_data: proc { |order_cycle| order_cycle.schedule_ids.to_s } }

  attr_accessor :incoming_exchanges, :outgoing_exchanges

  before_update :reset_opened_at, if: :will_save_change_to_orders_open_at?
  before_update :reset_processed_at, if: :will_save_change_to_orders_close_at?
  after_save :sync_subscriptions, if: :opening?

  validates :name, :coordinator_id, presence: true
  validate :orders_close_at_after_orders_open_at?

  preference :product_selection_from_coordinator_inventory_only, :boolean, default: false

  scope :active, lambda {
    where('order_cycles.orders_open_at <= ? AND order_cycles.orders_close_at >= ?',
          Time.zone.now,
          Time.zone.now)
  }
  scope :active_or_complete, lambda { where('order_cycles.orders_open_at <= ?', Time.zone.now) }
  scope :inactive, lambda {
    where('order_cycles.orders_open_at > ? OR order_cycles.orders_close_at < ?',
          Time.zone.now,
          Time.zone.now)
  }
  scope :upcoming, lambda { where('order_cycles.orders_open_at > ?', Time.zone.now) }
  scope :not_closed, lambda {
    where('order_cycles.orders_close_at > ? OR order_cycles.orders_close_at IS NULL', Time.zone.now)
  }
  scope :closed, lambda {
    where('order_cycles.orders_close_at < ?',
          Time.zone.now).order("order_cycles.orders_close_at DESC")
  }
  scope :unprocessed, -> { where(processed_at: nil) }
  scope :undated, -> { where('order_cycles.orders_open_at IS NULL OR orders_close_at IS NULL') }
  scope :dated, -> { where('orders_open_at IS NOT NULL AND orders_close_at IS NOT NULL') }

  scope :soonest_closing,      lambda { active.order('order_cycles.orders_close_at ASC') }
  # This scope returns all the closed orders
  scope :most_recently_closed, lambda { closed.order('order_cycles.orders_close_at DESC') }

  scope :soonest_opening,      lambda { upcoming.order('order_cycles.orders_open_at ASC') }

  scope :by_name, -> { order('name') }

  scope :with_distributor, lambda { |distributor|
    joins(:exchanges).merge(Exchange.outgoing).merge(Exchange.to_enterprise(distributor))
  }

  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      where(nil)
    else
      where(coordinator_id: user.enterprises.to_a)
    end
  }

  # Return order cycles that user coordinates, sends to or receives from
  scope :visible_by, lambda { |user|
    if user.has_spree_role?('admin')
      where(nil)
    else
      with_exchanging_enterprises_outer.
        where('order_cycles.coordinator_id IN (?) OR enterprises.id IN (?)',
              user.enterprises.map(&:id),
              user.enterprises.map(&:id)).
        select('DISTINCT order_cycles.*')
    end
  }

  scope :with_exchanging_enterprises_outer, lambda {
    joins("LEFT OUTER JOIN exchanges ON (exchanges.order_cycle_id = order_cycles.id)").
      joins("LEFT OUTER JOIN enterprises
          ON (enterprises.id = exchanges.sender_id OR enterprises.id = exchanges.receiver_id)")
  }

  scope :involving_managed_distributors_of, lambda { |user|
    enterprises = Enterprise.managed_by(user)

    # Order cycles where I managed an enterprise at either end of an outgoing exchange
    # ie. coordinator or distributor
    joins(:exchanges).merge(Exchange.outgoing).
      where('exchanges.receiver_id IN (?) OR exchanges.sender_id IN (?)',
            enterprises.pluck(:id),
            enterprises.pluck(:id)).
      select('DISTINCT order_cycles.*')
  }

  scope :involving_managed_producers_of, lambda { |user|
    enterprises = Enterprise.managed_by(user)

    # Order cycles where I managed an enterprise at either end of an incoming exchange
    # ie. coordinator or producer
    joins(:exchanges).merge(Exchange.incoming).
      where('exchanges.receiver_id IN (?) OR exchanges.sender_id IN (?)',
            enterprises.pluck(:id),
            enterprises.pluck(:id)).
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
        select("exchanges.receiver_id AS receiver_id,
                MIN(order_cycles.orders_close_at) AS earliest_close_at").
        map { |ex| [ex.receiver_id, ex.earliest_close_at.to_time] }
    ]
  end

  def attachable_distributor_payment_methods
    DistributorPaymentMethod.joins(:payment_method).
      merge(Spree::PaymentMethod.available).
      where("distributor_id IN (?)", distributor_ids)
  end

  def attachable_distributor_shipping_methods
    DistributorShippingMethod.joins(:shipping_method).
      merge(Spree::ShippingMethod.frontend).
      where("distributor_id IN (?)", distributor_ids)
  end

  def clone!
    OrderCycleClone.new(self).create
  end

  def variants
    Spree::Variant.
      joins(:exchanges).
      merge(Exchange.in_order_cycle(self)).
      select('DISTINCT spree_variants.*').
      to_a # http://stackoverflow.com/q/15110166
  end

  def supplied_variants
    exchanges.incoming.map(&:variants).flatten.uniq.reject(&:deleted?)
  end

  def distributed_variants
    exchanges.outgoing.map(&:variants).flatten.uniq.reject(&:deleted?)
  end

  def variants_distributed_by(distributor)
    return Spree::Variant.where("1=0") if distributor.blank?

    Spree::Variant.
      joins(:exchanges).
      merge(distributor.inventory_variants).
      merge(Exchange.in_order_cycle(self)).
      merge(Exchange.outgoing).
      merge(Exchange.to_enterprise(distributor))
  end

  def products_distributed_by(distributor)
    variants_distributed_by(distributor).map(&:product).uniq
  end

  def products
    variants.map(&:product).uniq
  end

  def has_distributor?(distributor)
    distributors.include? distributor
  end

  def has_variant?(variant)
    variants.include? variant
  end

  def dated?
    !undated?
  end

  def undated?
    orders_open_at.nil? || orders_close_at.nil?
  end

  def upcoming?
    orders_open_at && Time.zone.now < orders_open_at
  end

  def open?
    orders_open_at && orders_close_at &&
      Time.zone.now > orders_open_at && Time.zone.now < orders_close_at
  end

  def closed?
    orders_close_at && Time.zone.now > orders_close_at
  end

  def exchange_for_distributor(distributor)
    exchanges.outgoing.to_enterprises([distributor]).first
  end

  def exchange_for_supplier(supplier)
    exchanges.incoming.from_enterprises([supplier]).first
  end

  def receival_instructions_for(supplier)
    exchange_for_supplier(supplier)&.receival_instructions
  end

  def pickup_time_for(distributor)
    exchange_for_distributor(distributor)&.pickup_time || distributor.next_collection_at
  end

  def pickup_instructions_for(distributor)
    exchange_for_distributor(distributor)&.pickup_instructions
  end

  def exchanges_carrying(variant, distributor)
    exchanges.supplying_to(distributor).with_variant(variant)
  end

  def exchanges_supplying(order)
    variant_ids_relation = Spree::LineItem.in_orders(order).select(:variant_id)
    exchanges.supplying_to(order.distributor).with_any_variant(variant_ids_relation)
  end

  def coordinated_by?(user)
    coordinator.users.include? user
  end

  def items_bought_by_user(user, distributor)
    # The Spree::Order.complete scope only checks for completed_at date
    #   it does not ensure state is "complete"
    orders = Spree::Order.complete.where(state: "complete",
                                         user_id: user,
                                         distributor_id: distributor,
                                         order_cycle_id: self)
    scoper = OpenFoodNetwork::ScopeVariantToHub.new(distributor)
    items = Spree::LineItem.includes(:variant).joins(:order).merge(orders).to_a
    items.each { |li| scoper.scope(li.variant) }
  end

  def distributor_payment_methods
    if simple? || selected_distributor_payment_methods.none?
      attachable_distributor_payment_methods
    else
      attachable_distributor_payment_methods.where(
        "distributors_payment_methods.id IN (?) OR distributor_id NOT IN (?)",
        selected_distributor_payment_methods.map(&:id),
        selected_distributor_payment_methods.map(&:distributor_id)
      )
    end
  end

  def distributor_shipping_methods
    if simple? || selected_distributor_shipping_methods.none?
      attachable_distributor_shipping_methods
    else
      attachable_distributor_shipping_methods.where(
        "distributors_shipping_methods.id IN (?) OR distributor_id NOT IN (?)",
        selected_distributor_shipping_methods.map(&:id),
        selected_distributor_shipping_methods.map(&:distributor_id)
      )
    end
  end

  def simple?
    coordinator.sells == 'own'
  end

  private

  def opening?
    (open? || upcoming?) && saved_change_to_orders_close_at? && was_closed?
  end

  def was_closed?
    orders_close_at_previously_was.blank? || Time.zone.now > orders_close_at_previously_was
  end

  def sync_subscriptions
    return unless schedule_ids.any?

    OrderManagement::Subscriptions::ProxyOrderSyncer.new(
      Subscription.where(schedule_id: schedule_ids)
    ).sync!
  end

  def orders_close_at_after_orders_open_at?
    return if orders_open_at.blank? || orders_close_at.blank?
    return if orders_close_at > orders_open_at

    errors.add(:orders_close_at, :after_orders_open_at)
  end

  def reset_opened_at
    # Reset only if order cycle is opening again at a later date
    return unless orders_open_at.present? && orders_open_at_was.present?
    return unless orders_open_at > orders_open_at_was

    self.opened_at = nil
  end

  def reset_processed_at
    return unless orders_close_at.present? && orders_close_at_was.present?
    return unless orders_close_at > orders_close_at_was

    self.processed_at = nil
    self.mails_sent = false
  end
end
