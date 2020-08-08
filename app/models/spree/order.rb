require 'spree/core/validators/email'
require 'spree/order/checkout'
require 'open_food_network/enterprise_fee_calculator'
require 'open_food_network/feature_toggle'
require 'open_food_network/tag_rule_applicator'
require 'concerns/order_shipment'

ActiveSupport::Notifications.subscribe('spree.order.contents_changed') do |_name, _start, _finish, _id, payload|
  payload[:order].reload.update_distribution_charge!
end

module Spree
  class Order < ActiveRecord::Base
    prepend OrderShipment
    include Checkout

    checkout_flow do
      go_to_state :address
      go_to_state :delivery
      go_to_state :payment, if: ->(order) {
        order.update_totals
        order.payment_required?
      }
      go_to_state :complete
      remove_transition from: :delivery, to: :confirm
    end

    state_machine.after_transition to: :payment, do: :charge_shipping_and_payment_fees!

    state_machine.event :restart_checkout do
      transition to: :cart, unless: :completed?
    end

    token_resource

    belongs_to :user, class_name: Spree.user_class.to_s
    belongs_to :created_by, class_name: Spree.user_class.to_s

    belongs_to :bill_address, foreign_key: :bill_address_id, class_name: 'Spree::Address'
    alias_attribute :billing_address, :bill_address

    belongs_to :ship_address, foreign_key: :ship_address_id, class_name: 'Spree::Address'
    alias_attribute :shipping_address, :ship_address

    has_many :state_changes, as: :stateful
    has_many :line_items, -> { order('created_at ASC') }, dependent: :destroy
    has_many :payments, dependent: :destroy
    has_many :return_authorizations, dependent: :destroy
    has_many :adjustments, -> { order "#{Spree::Adjustment.table_name}.created_at ASC" },
             as: :adjustable,
             dependent: :destroy

    has_many :line_item_adjustments, through: :line_items, source: :adjustments

    has_many :shipments, dependent: :destroy do
      def states
        pluck(:state).uniq
      end
    end

    belongs_to :order_cycle
    belongs_to :distributor, class_name: 'Enterprise'
    belongs_to :customer
    has_one :proxy_order
    has_one :subscription, through: :proxy_order

    accepts_nested_attributes_for :line_items
    accepts_nested_attributes_for :bill_address
    accepts_nested_attributes_for :ship_address
    accepts_nested_attributes_for :payments
    accepts_nested_attributes_for :shipments

    delegate :admin_and_handling_total, :payment_fee, :ship_total, to: :adjustments_fetcher

    # Needs to happen before save_permalink is called
    before_validation :set_currency
    before_validation :generate_order_number, on: :create
    before_validation :clone_billing_address, if: :use_billing?
    before_validation :associate_customer, unless: :customer_id?
    before_validation :ensure_customer, unless: :customer_is_valid?

    validates :customer, presence: true, if: :require_customer?
    validate :products_available_from_new_distribution, if: lambda { distributor_id_changed? || order_cycle_id_changed? }
    validate :disallow_guest_order

    attr_accessor :use_billing

    before_create :link_by_email
    after_create :create_tax_charge!

    validate :has_available_shipment
    validate :has_available_payment
    validates :email, presence: true,
                      format: /\A([\w\.%\+\-']+)@([\w\-]+\.)+([\w]{2,})\z/i,
                      if: :require_email

    make_permalink field: :number

    before_save :update_shipping_fees!, if: :complete?
    before_save :update_payment_fees!, if: :complete?

    class_attribute :update_hooks
    self.update_hooks = Set.new

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

    def self.by_number(number)
      where(number: number)
    end

    def self.between(start_date, end_date)
      where(created_at: start_date..end_date)
    end

    def self.by_customer(customer)
      joins(:user).where("#{Spree.user_class.table_name}.email" => customer)
    end

    def self.by_state(state)
      where(state: state)
    end

    def self.complete
      where('completed_at IS NOT NULL')
    end

    def self.incomplete
      where(completed_at: nil)
    end

    # Use this method in other gems that wish to register their own custom logic
    # that should be called after Order#update
    def self.register_update_hook(hook)
      self.update_hooks.add(hook)
    end

    # For compatiblity with Calculator::PriceSack
    def amount
      line_items.inject(0.0) { |sum, li| sum + li.amount }
    end

    def currency
      self[:currency] || Spree::Config[:currency]
    end

    def display_outstanding_balance
      Spree::Money.new(outstanding_balance, { currency: currency })
    end

    def display_item_total
      Spree::Money.new(item_total, { currency: currency })
    end

    def display_adjustment_total
      Spree::Money.new(adjustment_total, { currency: currency })
    end

    def display_tax_total
      Spree::Money.new(tax_total, { currency: currency })
    end

    def display_ship_total
      Spree::Money.new(ship_total, { currency: currency })
    end

    def display_total
      Spree::Money.new(total, { currency: currency })
    end

    def to_param
      number.to_s.to_url.upcase
    end

    def completed?
      completed_at.present?
    end

    # Indicates whether or not the user is allowed to proceed to checkout.
    # Currently this is implemented as a check for whether or not there is at
    # least one LineItem in the Order.  Feel free to override this logic in your
    # own application if you require additional steps before allowing a checkout.
    def checkout_allowed?
      line_items.count > 0
    end

    def changes_allowed?
      complete? && distributor.andand.allow_order_changes? && order_cycle.andand.open?
    end

    # Is this a free order in which case the payment step should be skipped
    # This allows unpaid subscription orders to be completed.
    #   Subscriptions place orders at the beginning of an order cycle. They need to
    #   be completed to draw from stock levels and trigger emails.
    def payment_required?
      total.to_f > 0.0 && !skip_payment_for_subscription?
    end

    # Indicates the number of items in the order
    def item_count
      line_items.inject(0) { |sum, li| sum + li.quantity }
    end

    def backordered?
      shipments.any?(&:backordered?)
    end

    # Returns the relevant zone (if any) to be used for taxation purposes.
    # Uses default tax zone unless there is a specific match
    def tax_zone
      Zone.match(tax_address) || Zone.default_tax
    end

    # Indicates whether tax should be backed out of the price calcualtions in
    # cases where prices include tax but the customer is not required to pay
    # taxes in that case.
    def exclude_tax?
      return false unless Spree::Config[:prices_inc_tax]
      return tax_zone != Zone.default_tax
    end

    # Returns the address for taxation based on configuration
    def tax_address
      Spree::Config[:tax_using_ship_address] ? ship_address : bill_address
    end

    # Array of totals grouped by Adjustment#label. Useful for displaying line item
    # adjustments on an invoice. For example, you can display tax breakout for
    # cases where tax is included in price.
    def line_item_adjustment_totals
      Hash[self.line_item_adjustments.eligible.group_by(&:label).map do |label, adjustments|
        total = adjustments.sum(&:amount)
        [label, Spree::Money.new(total, { currency: currency })]
      end]
    end

    def updater
      @updater ||= OrderManagement::Order::Updater.new(self)
    end

    def update!
      updater.update
    end

    def update_totals
      updater.update_totals
    end

    def clone_billing_address
      if bill_address and self.ship_address.nil?
        self.ship_address = bill_address.clone
      else
        self.ship_address.attributes = bill_address.attributes.except('id', 'updated_at', 'created_at')
      end
      true
    end

    def allow_cancel?
      return false unless completed? and state != 'canceled'
      shipment_state.nil? || %w{ready backorder pending}.include?(shipment_state)
    end

    def allow_resume?
      # we shouldn't allow resume for legacy orders b/c we lack the information
      # necessary to restore to a previous state
      return false if state_changes.empty? || state_changes.last.previous_state.nil?
      true
    end

    def awaiting_returns?
      return_authorizations.any? { |return_authorization| return_authorization.authorized? }
    end

    # This is currently used when adding a variant to an order in the BackOffice.
    # Spree::OrderContents#add is equivalent but slightly different from add_variant below.
    def contents
      @contents ||= Spree::OrderContents.new(self)
    end

    # This is currently used when adding a variant to an order in the FrontOffice.
    # This add_variant is equivalent but slightly different from Spree::OrderContents#add above.
    # Spree::OrderContents#add is the more modern version in Spree history
    #   but this add_variant has been customized for OFN FrontOffice.
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

    # Associates the specified user with the order.
    def associate_user!(user)
      self.user = user
      self.email = user.email
      self.created_by = user if self.created_by.blank?

      if persisted?
        # immediately persist the changes we just made, but don't use save since we might have an invalid address associated
        self.class.unscoped.where(id: id).update_all(email: user.email, user_id: user.id, created_by_id: self.created_by_id)
      end
    end

    # FIXME refactor this method and implement validation using validates_* utilities
    def generate_order_number
      record = true
      while record
        random = "R#{Array.new(9){rand(9)}.join}"
        record = self.class.where(number: random).first
      end
      self.number = random if self.number.blank?
      self.number
    end

    def shipped_shipments
      shipments.shipped
    end

    def contains?(variant)
      find_line_item_by_variant(variant).present?
    end

    def quantity_of(variant)
      line_item = find_line_item_by_variant(variant)
      line_item ? line_item.quantity : 0
    end

    def find_line_item_by_variant(variant)
      line_items.detect { |line_item| line_item.variant_id == variant.id }
    end

    def ship_total
      adjustments.shipping.map(&:amount).sum
    end

    def tax_total
      adjustments.tax.map(&:amount).sum
    end

    # Creates new tax charges if there are any applicable rates. If prices already
    # include taxes then price adjustments are created instead.
    def create_tax_charge!
      Spree::TaxRate.adjust(self)
    end

    def outstanding_balance
      total - payment_total
    end

    def outstanding_balance?
     self.outstanding_balance != 0
    end

    def name
      if (address = bill_address || ship_address)
        "#{address.firstname} #{address.lastname}"
      end
    end

    def can_ship?
      self.complete? || self.resumed? || self.awaiting_return? || self.returned?
    end

    def credit_cards
      credit_card_ids = payments.from_credit_card.pluck(:source_id).uniq
      CreditCard.where(id: credit_card_ids)
    end

    # Finalizes an in progress order after checkout is complete.
    # Called after transition to complete state when payments will have been processed
    def finalize!
      touch :completed_at

      adjustments.update_all state: 'closed'

      # update payment and shipment(s) states, and save
      updater.update_payment_state
      shipments.each do |shipment|
        shipment.update!(self)
        shipment.finalize!
      end

      updater.update_shipment_state
      updater.before_save_hook
      save
      updater.run_hooks

      deliver_order_confirmation_email

      self.state_changes.create(
        previous_state: 'cart',
        next_state:     'complete',
        name:           'order' ,
        user_id:        self.user_id
      )
    end

    def deliver_order_confirmation_email
      if subscription.blank?
        Delayed::Job.enqueue ConfirmOrderJob.new(id)
      end
    end

    # Helper methods for checkout steps
    def paid?
      payment_state == 'paid' || payment_state == 'credit_owed'
    end

    def available_payment_methods
      @available_payment_methods ||= PaymentMethod.available(:front_end)
    end

    # "Checkout" is the initial state and, for card payments, "pending" is the state after authorization
    # These are both valid states to process the payment
    def pending_payments
      (payments.select(&:pending?) + payments.select(&:processing?) + payments.select(&:checkout?)).uniq
    end

    # processes any pending payments and must return a boolean as it's
    # return value is used by the checkout state_machine to determine
    # success or failure of the 'complete' event for the order
    #
    # Returns:
    # - true if all pending_payments processed successfully
    # - true if a payment failed, ie. raised a GatewayError
    #   which gets rescued and converted to TRUE when
    #   :allow_checkout_gateway_error is set to true
    # - false if a payment failed, ie. raised a GatewayError
    #   which gets rescued and converted to FALSE when
    #   :allow_checkout_on_gateway_error is set to false
    #
    def process_payments!
      if pending_payments.empty?
        raise Core::GatewayError.new Spree.t(:no_pending_payments)
      else
        pending_payments.each do |payment|
          break if payment_total >= total

          payment.process!

          if payment.completed?
            self.payment_total += payment.amount
          end
        end
      end
    rescue Core::GatewayError => e
      result = !!Spree::Config[:allow_checkout_on_gateway_error]
      errors.add(:base, e.message) and return result
    end

    def billing_firstname
      bill_address.try(:firstname)
    end

    def billing_lastname
      bill_address.try(:lastname)
    end

    def products
      line_items.map(&:product)
    end

    def variants
      line_items.map(&:variant)
    end

    def insufficient_stock_lines
      line_items.select &:insufficient_stock?
    end

    def merge!(order)
      order.line_items.each do |line_item|
        next unless line_item.currency == currency
        current_line_item = self.line_items.find_by(variant: line_item.variant)
        if current_line_item
          current_line_item.quantity += line_item.quantity
          current_line_item.save
        else
          line_item.order_id = self.id
          line_item.save
        end
      end
      # So that the destroy doesn't take out line items which may have been re-assigned
      order.line_items.reload
      order.destroy
    end

    def empty!
      line_items.destroy_all
      adjustments.destroy_all
      payments.clear
      shipments.destroy_all
    end

    def clear_adjustments!
      self.adjustments.destroy_all
      self.line_item_adjustments.destroy_all
    end

    def has_step?(step)
      checkout_steps.include?(step)
    end

    def state_changed(name)
      state = "#{name}_state"
      if persisted?
        old_state = self.send("#{state}_was")
        self.state_changes.create(
          previous_state: old_state,
          next_state:     self.send(state),
          name:           name,
          user_id:        self.user_id
        )
      end
    end

    def shipped?
      %w(partial shipped).include?(shipment_state)
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

    def create_proposed_shipments
      adjustments.shipping.delete_all
      shipments.destroy_all

      packages = OrderManagement::Stock::Coordinator.new(self).packages
      packages.each do |package|
        shipments << package.to_shipment
      end

      shipments
    end

    # Clean shipments and make order back to address state
    #
    # At some point the might need to force the order to transition from address
    # to delivery again so that proper updated shipments are created.
    # e.g. customer goes back from payment step and changes order items 
    def ensure_updated_shipments
      if shipments.any?
        self.shipments.destroy_all
        self.update_column(:state, "address")
      end
    end

    def refresh_shipment_rates
      shipments.map &:refresh_rates
    end

    def products_available_from_new_distribution
      # Check that the line_items in the current order are available from a newly selected distribution
      errors.add(:base, I18n.t(:spree_order_availability_error)) unless OrderCycleDistributedVariants.new(order_cycle, distributor).distributes_order_variants?(self)
    end

    def disallow_guest_order
      if using_guest_checkout? && registered_email?
        errors.add(:base, I18n.t('devise.failure.already_registered'))
      end
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

    def set_order_cycle!(order_cycle)
      return if self.order_cycle == order_cycle

      self.order_cycle = order_cycle
      self.distributor = nil unless order_cycle.nil? || order_cycle.has_distributor?(distributor)
      empty!
      save!
    end

    def remove_variant(variant)
      line_items(:reload)
      current_item = find_line_item_by_variant(variant)
      current_item.andand.destroy
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

      def link_by_email
        self.email = user.email if self.user
      end

      # Determine if email is required (we don't want validation errors before we hit the checkout)
      def require_email
        return true unless new_record? or state == 'cart'
      end

      def ensure_line_items_present
        unless line_items.present?
          errors.add(:base, Spree.t(:there_are_no_items_for_this_order)) and return false
        end
      end

      def has_available_shipment
        return unless has_step?("delivery")
        return unless address?
        return unless ship_address && ship_address.valid?
        # errors.add(:base, :no_shipping_methods_available) if available_shipping_methods.empty?
      end

      def ensure_available_shipping_rates
        if shipments.empty? || shipments.any? { |shipment| shipment.shipping_rates.blank? }
          errors.add(:base, Spree.t(:items_cannot_be_shipped)) and return false
        end
      end

      def has_available_payment
        return unless delivery?
        # errors.add(:base, :no_payment_methods_available) if available_payment_methods.empty?
      end

      def after_cancel
        shipments.each { |shipment| shipment.cancel! }

        OrderMailer.cancel_email(self.id).deliver
        self.payment_state = 'credit_owed' unless shipped?
      end

      def after_resume
        shipments.each { |shipment| shipment.resume! }
      end

      def use_billing?
        @use_billing == true || @use_billing == 'true' || @use_billing == '1'
      end

      def set_currency
        self.currency = Spree::Config[:currency] if self[:currency].nil?
      end

    def using_guest_checkout?
      require_email && !user.andand.id
    end

    def registered_email?
      Spree.user_class.exists?(email: email)
    end

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
end
