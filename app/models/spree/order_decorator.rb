require 'open_food_network/enterprise_fee_calculator'
require 'open_food_network/feature_toggle'
require 'open_food_network/tag_rule_applicator'
require 'concerns/order_shipment'

ActiveSupport::Notifications.subscribe('spree.order.contents_changed') do |_name, _start, _finish, _id, payload|
  payload[:order].reload.update_distribution_charge!
end

Spree::Order.class_eval do
  prepend OrderShipment

  delegate :admin_and_handling_total, :payment_fee, :ship_total, to: :adjustments_fetcher

  belongs_to :order_cycle
  belongs_to :distributor, class_name: 'Enterprise'
  belongs_to :customer
  has_one :proxy_order
  has_one :subscription, through: :proxy_order

  # This removes "inverse_of: source" which breaks shipment adjustment calculations
  #   This change is done in Spree 2.1 (see https://github.com/spree/spree/commit/3fa44165c7825f79a2fa4eb79b99dc29944c5d55)
  #   When OFN gets to Spree 2.1, this can be removed
  has_many :adjustments, -> { order "#{Spree::Adjustment.table_name}.created_at ASC" },
           as: :adjustable,
           dependent: :destroy

  validates :customer, presence: true, if: :require_customer?
  validate :products_available_from_new_distribution, if: lambda { distributor_id_changed? || order_cycle_id_changed? }
  validate :disallow_guest_order

  # The EmailValidator introduced in Spree 2.1 is not working
  # So here we remove it and re-introduce the regexp validation rule from Spree 2.0
  _validate_callbacks.each do |callback|
    if callback.raw_filter.respond_to? :attributes
      callback.raw_filter.attributes.delete :email
    end
  end
  validates :email, presence: true, format: /\A([\w\.%\+\-']+)@([\w\-]+\.)+([\w]{2,})\z/i,
                    if: :require_email

  before_validation :associate_customer, unless: :customer_id?
  before_validation :ensure_customer, unless: :customer_is_valid?

  before_save :update_shipping_fees!, if: :complete?
  before_save :update_payment_fees!, if: :complete?

  # Orders are confirmed with their payment, we don't use the confirm step.
  # Here we remove that step from Spree's checkout state machine.
  # See: https://guides.spreecommerce.org/developer/checkout.html#modifying-the-checkout-flow
  remove_checkout_step :confirm

  state_machine.after_transition to: :payment, do: :charge_shipping_and_payment_fees!

  state_machine.event :restart_checkout do
    transition to: :cart, unless: :completed?
  end

  # -- Scopes
  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      where(nil)
    else
      # Find orders that are distributed by the user or have products supplied by the user
      # WARNING: This only filters orders, you'll need to filter line items separately using LineItem.managed_by
      with_line_items_variants_and_products_outer.
        where('spree_orders.distributor_id IN (?) OR spree_products.supplier_id IN (?)',
              user.enterprises.select(&:id),
              user.enterprises.select(&:id)).
        select('DISTINCT spree_orders.*')
    end
  }

  scope :distributed_by_user, lambda { |user|
    if user.has_spree_role?('admin')
      where(nil)
    else
      where('spree_orders.distributor_id IN (?)', user.enterprises.select(&:id))
    end
  }

  scope :with_line_items_variants_and_products_outer, lambda {
    joins('LEFT OUTER JOIN spree_line_items ON (spree_line_items.order_id = spree_orders.id)').
      joins('LEFT OUTER JOIN spree_variants ON (spree_variants.id = spree_line_items.variant_id)').
      joins('LEFT OUTER JOIN spree_products ON (spree_products.id = spree_variants.product_id)')
  }

  scope :not_state, lambda { |state|
    where("state != ?", state)
  }

  def updater
    @updater ||= OrderManagement::Order::Updater.new(self)
  end

  def create_proposed_shipments
    adjustments.shipping.delete_all
    shipments.destroy_all

    packages = OrderManagement::Stock::Coordinator.new(self).packages
    packages.each do |package|
      shipments << package.to_shipment
    end

    shipments
  end

  # -- Methods
  def products_available_from_new_distribution
    # Check that the line_items in the current order are available from a newly selected distribution
    errors.add(:base, I18n.t(:spree_order_availability_error)) unless OrderCycleDistributedVariants.new(order_cycle, distributor).distributes_order_variants?(self)
  end

  def using_guest_checkout?
    require_email && !user.andand.id
  end

  def registered_email?
    Spree.user_class.exists?(email: email)
  end

  def disallow_guest_order
    if using_guest_checkout? && registered_email?
      errors.add(:base, I18n.t('devise.failure.already_registered'))
    end
  end

  def empty_with_clear_shipping_and_payments!
    empty_without_clear_shipping_and_payments!
    payments.clear
    shipments.destroy_all
  end
  alias_method_chain :empty!, :clear_shipping_and_payments

  def set_order_cycle!(order_cycle)
    return if self.order_cycle == order_cycle

    self.order_cycle = order_cycle
    self.distributor = nil unless order_cycle.nil? || order_cycle.has_distributor?(distributor)
    empty!
    save!
  end

  # "Checkout" is the initial state and, for card payments, "pending" is the state after authorization
  # These are both valid states to process the payment
  def pending_payments
    (payments.select(&:pending?) + payments.select(&:processing?) + payments.select(&:checkout?)).uniq
  end

  def remove_variant(variant)
    line_items(:reload)
    current_item = find_line_item_by_variant(variant)
    current_item.andand.destroy
  end

  # Overridden to support max_quantity
  def add_variant(variant, quantity = 1, max_quantity = nil, currency = nil)
    line_items(:reload)
    current_item = find_line_item_by_variant(variant)

    # Notify bugsnag if we get line items with a quantity of zero
    if quantity == 0
      Bugsnag.notify(RuntimeError.new("Zero Quantity Line Item"),
                     current_item: current_item.as_json,
                     line_items: line_items.map(&:id),
                     variant: variant.as_json)
    end

    if current_item
      current_item.quantity = quantity
      current_item.max_quantity = max_quantity

      # This is the original behaviour, behaviour above is so that we can resolve the order populator bug
      # current_item.quantity ||= 0
      # current_item.max_quantity ||= 0
      # current_item.quantity += quantity.to_i
      # current_item.max_quantity += max_quantity.to_i
      current_item.currency = currency unless currency.nil?
      current_item.save
    else
      current_item = Spree::LineItem.new(quantity: quantity, max_quantity: max_quantity)
      current_item.variant = variant
      if currency
        current_item.currency = currency unless currency.nil?
        current_item.price    = variant.price_in(currency).amount
      else
        current_item.price    = variant.price
      end
      line_items << current_item
    end

    reload
    current_item
  end

  # After changing line items of a completed order
  def update_shipping_fees!
    shipments.each do |shipment|
      next if shipment.shipped?

      update_adjustment! shipment.adjustment if shipment.adjustment
      save_or_rescue_shipment(shipment)
    end
  end

  def save_or_rescue_shipment(shipment)
    shipment.save # updates included tax
  rescue ActiveRecord::RecordNotUnique => e
    # This error was seen in production on `shipment.save` above.
    # It caused lost payments and duplicate payments due to database rollbacks.
    # While we don't understand the cause of this error yet, we rescue here
    # because an outdated shipping fee is not as bad as a lost payment.
    # And the shipping fee is already up-to-date when this error occurs.
    # https://github.com/openfoodfoundation/openfoodnetwork/issues/3924
    Bugsnag.notify(e) do |report|
      report.add_tab(:order, attributes)
      report.add_tab(:shipment, shipment.attributes)
      report.add_tab(:shipment_in_db, Spree::Shipment.find_by(id: shipment.id).attributes)
    end
  end

  # After changing line items of a completed order
  def update_payment_fees!
    payments.each do |payment|
      next if payment.completed?

      update_adjustment! payment.adjustment if payment.adjustment
      payment.save
    end
  end

  def cap_quantity_at_stock!
    line_items.includes(variant: :stock_items).all.each(&:cap_quantity_at_stock!)
  end

  def set_distributor!(distributor)
    self.distributor = distributor
    self.order_cycle = nil unless order_cycle.andand.has_distributor? distributor
    save!
  end

  def set_distribution!(distributor, order_cycle)
    self.distributor = distributor
    self.order_cycle = order_cycle
    save!
  end

  def distribution_set?
    distributor && order_cycle
  end

  def update_distribution_charge!
    # `with_lock` acquires an exclusive row lock on order so no other
    # requests can update it until the transaction is commited.
    # See https://github.com/rails/rails/blob/3-2-stable/activerecord/lib/active_record/locking/pessimistic.rb#L69
    # and https://www.postgresql.org/docs/current/static/sql-select.html#SQL-FOR-UPDATE-SHARE
    with_lock do
      EnterpriseFee.clear_all_adjustments_on_order self

      loaded_line_items =
        line_items.includes(variant: :product, order: [:distributor, :order_cycle]).all

      loaded_line_items.each do |line_item|
        if provided_by_order_cycle? line_item
          OpenFoodNetwork::EnterpriseFeeCalculator.new.create_line_item_adjustments_for line_item
        end
      end

      if order_cycle
        OpenFoodNetwork::EnterpriseFeeCalculator.new.create_order_adjustments_for self
      end
    end
  end

  def set_variant_attributes(variant, attributes)
    line_item = find_line_item_by_variant(variant)

    if line_item
      if attributes.key?(:max_quantity) && attributes[:max_quantity].to_i < line_item.quantity
        attributes[:max_quantity] = line_item.quantity
      end

      line_item.assign_attributes(attributes)
      line_item.save!
    end
  end

  def line_item_variants
    if line_items.loaded?
      line_items.map(&:variant)
    else
      line_items.includes(:variant).map(&:variant)
    end
  end

  # Show already bought line items of this order cycle
  def finalised_line_items
    return [] unless order_cycle && user && distributor

    order_cycle.items_bought_by_user(user, distributor)
  end

  # Does this order have shipments that can be shipped?
  def ready_to_ship?
    shipments.any?(&:can_ship?)
  end

  # Ship all pending orders
  def ship
    shipments.each do |s|
      s.ship if s.can_ship?
    end
  end

  def shipping_tax
    adjustments(:reload).shipping.sum(&:included_tax)
  end

  def enterprise_fee_tax
    adjustments(:reload).enterprise_fee.sum(&:included_tax)
  end

  def total_tax
    (adjustments + price_adjustments).sum(&:included_tax)
  end

  def price_adjustments
    adjustments = []

    line_items.each { |line_item| adjustments.concat line_item.adjustments }

    adjustments
  end

  def price_adjustment_totals
    Hash[tax_adjustment_totals.map do |tax_rate, tax_amount|
      [tax_rate.name,
       Spree::Money.new(tax_amount, currency: currency)]
    end]
  end

  def has_taxes_included
    !line_items.with_tax.empty?
  end

  # Overrride of Spree method, that allows us to send separate confirmation emails to user and shop owners
  def deliver_order_confirmation_email
    if subscription.blank?
      Delayed::Job.enqueue ConfirmOrderJob.new(id)
    end
  end

  def changes_allowed?
    complete? && distributor.andand.allow_order_changes? && order_cycle.andand.open?
  end

  # Override Spree method to allow unpaid orders to be completed.
  # Subscriptions place orders at the beginning of an order cycle. They need to
  # be completed to draw from stock levels and trigger emails.
  # Spree doesn't allow this. Other options would be to introduce an additional
  # order state or implement a special proxy payment method.
  # https://github.com/openfoodfoundation/openfoodnetwork/pull/3012#issuecomment-438146484
  def payment_required?
    total.to_f > 0.0 && !skip_payment_for_subscription?
  end

  def address_from_distributor
    address = distributor.address.clone
    if bill_address
      address.firstname = bill_address.firstname
      address.lastname = bill_address.lastname
      address.phone = bill_address.phone
    end
    address
  end

  # Update attributes of a record in the database without callbacks, validations etc.
  #   This was originally an extension to ActiveRecord in Spree but only used for Spree::Order
  def update_attributes_without_callbacks(attributes)
    assign_attributes(attributes)
    Spree::Order.where(id: id).update_all(attributes)
  end

  private

  def adjustments_fetcher
    @adjustments_fetcher ||= OrderAdjustmentsFetcher.new(self)
  end

  def skip_payment_for_subscription?
    subscription.present? && order_cycle.orders_close_at.andand > Time.zone.now
  end

  def provided_by_order_cycle?(line_item)
    order_cycle_variants = order_cycle.andand.variants || []
    order_cycle_variants.include? line_item.variant
  end

  def require_customer?
    return true unless new_record? || state == 'cart'
  end

  def customer_is_valid?
    return true unless require_customer?

    customer.present? && customer.enterprise_id == distributor_id && customer.email == email_for_customer
  end

  def email_for_customer
    (user.andand.email || email).andand.downcase
  end

  def associate_customer
    return customer if customer.present?

    self.customer = Customer.of(distributor).find_by(email: email_for_customer)
  end

  def ensure_customer
    unless associate_customer
      customer_name = bill_address.andand.full_name
      self.customer = Customer.create(enterprise: distributor, email: email_for_customer, user: user, name: customer_name, bill_address: bill_address.andand.clone, ship_address: ship_address.andand.clone)
    end
  end

  def update_adjustment!(adjustment)
    return if adjustment.finalized?

    state = adjustment.state
    adjustment.state = 'open'
    adjustment.update!
    update!
    adjustment.state = state
  end

  # object_params sets the payment amount to the order total, but it does this
  # before the shipping method is set. This results in the customer not being
  # charged for their order's shipping. To fix this, we refresh the payment
  # amount here.
  def charge_shipping_and_payment_fees!
    update_totals
    return unless pending_payments.any?

    pending_payments.first.update_attribute :amount, total
  end
end
