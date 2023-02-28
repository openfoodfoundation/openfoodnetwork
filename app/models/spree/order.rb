# frozen_string_literal: true

require 'spree/order/checkout'
require 'open_food_network/enterprise_fee_calculator'
require 'open_food_network/feature_toggle'
require 'open_food_network/tag_rule_applicator'

module Spree
  class Order < ApplicationRecord
    include OrderShipment
    include Checkout
    include Balance
    include SetUnusedAddressFields

    searchable_attributes :number, :state, :shipment_state, :payment_state, :distributor_id,
                          :order_cycle_id, :email, :total, :customer_id
    searchable_associations :shipping_method, :bill_address, :distributor
    searchable_scopes :complete, :incomplete

    checkout_flow do
      go_to_state :address
      go_to_state :delivery
      go_to_state :payment, if: ->(order) {
        order.update_totals
        order.payment_required?
      }
      go_to_state :confirmation, if: ->(order) {
        OpenFoodNetwork::FeatureToggle.enabled? :split_checkout, order.created_by
      }
      go_to_state :complete
    end

    attr_accessor :use_billing, :checkout_processing, :save_bill_address, :save_ship_address

    token_resource

    belongs_to :user, class_name: "Spree::User"
    belongs_to :created_by, class_name: "Spree::User"

    belongs_to :bill_address, class_name: 'Spree::Address'
    alias_attribute :billing_address, :bill_address

    belongs_to :ship_address, class_name: 'Spree::Address'
    alias_attribute :shipping_address, :ship_address

    has_many :state_changes, as: :stateful
    has_many :line_items, -> {
                            order('created_at ASC')
                          }, class_name: "Spree::LineItem", dependent: :destroy
    has_many :payments, dependent: :destroy
    has_many :return_authorizations, dependent: :destroy, inverse_of: :order
    has_many :adjustments, -> { order "#{Spree::Adjustment.table_name}.created_at ASC" },
             as: :adjustable,
             dependent: :destroy

    has_many :shipments, dependent: :destroy do
      def states
        pluck(:state).uniq
      end
    end

    has_many :line_item_adjustments, through: :line_items, source: :adjustments
    has_many :shipment_adjustments, through: :shipments, source: :adjustments
    has_many :all_adjustments, class_name: 'Spree::Adjustment', dependent: :destroy

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
    delegate :update_totals, to: :updater
    delegate :create_line_item_fees!, :create_order_fees!, :update_order_fees!,
             :update_line_item_fees!, :recreate_all_fees!, to: :fee_handler

    # Needs to happen before save_permalink is called
    before_validation :set_currency
    before_validation :generate_order_number, on: :create
    before_validation :clone_billing_address, if: :use_billing?
    before_validation :ensure_customer

    before_create :link_by_email
    after_create :create_tax_charge!

    validates :customer, presence: true, if: :require_customer?
    validate :products_available_from_new_distribution, if: lambda {
      distributor_id_changed? || order_cycle_id_changed?
    }
    validate :disallow_guest_order
    validates :email, presence: true,
                      format: /\A([\w.%+\-']+)@([\w\-]+\.)+(\w{2,})\z/i,
                      if: :require_email

    make_permalink field: :number

    before_save :update_shipping_fees!, if: :complete?
    before_save :update_payment_fees!, if: :complete?

    after_save_commit DefaultAddressUpdater

    attribute :send_cancellation_email, type: :boolean, default: true
    attribute :restock_items, type: :boolean, default: true
    # -- Scopes
    scope :not_empty, -> {
      left_outer_joins(:line_items).where.not(spree_line_items: { id: nil })
    }

    scope :managed_by, lambda { |user|
      if user.has_spree_role?('admin')
        where(nil)
      else
        # Find orders that are distributed by the user or have products supplied by the user
        # WARNING: This only filters orders,
        #   you'll need to filter line items separately using LineItem.managed_by
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

    # All the states an order can be in after completing the checkout
    FINALIZED_STATES = %w(complete canceled resumed awaiting_return returned).freeze

    scope :finalized, -> { where(state: FINALIZED_STATES) }
    scope :complete, -> { where.not(completed_at: nil) }
    scope :incomplete, -> { where(completed_at: nil) }
    scope :by_state, lambda { |state| where(state: state) }
    scope :not_state, lambda { |state| where.not(state: state) }

    def initialize(*_args)
      @checkout_processing = nil
      @manual_shipping_selection = nil

      super
    end

    # For compatiblity with Calculator::PriceSack
    def amount
      line_items.inject(0.0) { |sum, li| sum + li.amount }
    end

    def currency
      self[:currency] || Spree::Config[:currency]
    end

    def display_item_total
      Spree::Money.new(item_total, currency: currency)
    end

    def display_adjustment_total
      Spree::Money.new(adjustment_total, currency: currency)
    end

    def display_total
      Spree::Money.new(total, currency: currency)
    end

    def to_param
      number.to_s.parameterize.upcase
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
      complete? && distributor&.allow_order_changes? && order_cycle&.open?
    end

    # Is this a free order in which case the payment step should be skipped
    # This allows unpaid subscription orders to be completed.
    #   Subscriptions place orders at the beginning of an order cycle. They need to
    #   be completed to draw from stock levels and trigger emails.
    def payment_required?
      total.to_f > 0.0 && !skip_payment_for_subscription?
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

      tax_zone != Zone.default_tax
    end

    # Returns the address for taxation based on configuration
    def tax_address
      Spree::Config[:tax_using_ship_address] ? ship_address : bill_address
    end

    def updater
      @updater ||= OrderManagement::Order::Updater.new(self)
    end

    def update_order!
      updater.update
    end

    def clone_billing_address
      if bill_address && ship_address.nil?
        self.ship_address = bill_address.clone
      else
        ship_address.attributes = bill_address.attributes.except('id', 'updated_at', 'created_at')
      end
      true
    end

    def allow_cancel?
      return false unless completed? && (state != 'canceled')

      shipment_state.nil? || %w{ready backorder pending}.include?(shipment_state)
    end

    def allow_resume?
      # we shouldn't allow resume for legacy orders b/c we lack the information
      # necessary to restore to a previous state
      return false if state_changes.empty? || state_changes.last.previous_state.nil?

      true
    end

    def awaiting_returns?
      return_authorizations.any?(&:authorized?)
    end

    # OrderContents should always be used when modifying an order's line items
    def contents
      @contents ||= Spree::OrderContents.new(self)
    end

    # Associates the specified user with the order.
    def associate_user!(user)
      self.user = user
      self.email = user.email
      self.created_by = user if created_by.blank?

      return unless persisted?

      # Persist the changes we just made,
      #   but don't use save since we might have an invalid address associated
      self.class.unscoped.where(id: id).update_all(email: user.email,
                                                   user_id: user.id,
                                                   created_by_id: created_by_id)
    end

    # FIXME refactor this method and implement validation using validates_* utilities
    def generate_order_number
      record = true
      while record
        random = "R#{Array.new(9){ rand(9) }.join}"
        record = self.class.find_by(number: random)
      end
      self.number = random if number.blank?
      number
    end

    def shipped_shipments
      shipments.shipped
    end

    def contains?(variant)
      find_line_item_by_variant(variant).present?
    end

    def find_line_item_by_variant(variant)
      line_items.detect { |line_item| line_item.variant_id == variant.id }
    end

    def ship_total
      all_adjustments.shipping.sum(:amount)
    end

    # Creates new tax charges if there are any applicable rates. If prices already
    # include taxes then price adjustments are created instead.
    def create_tax_charge!
      return if state.in?(["cart", "address", "delivery"]) && OpenFoodNetwork::FeatureToggle.enabled?(:split_checkout)

      clear_legacy_taxes!

      Spree::TaxRate.adjust(self, line_items)
      Spree::TaxRate.adjust(self, shipments) if shipments.any?
      fee_handler.tax_enterprise_fees!
    end

    def name
      address = bill_address || ship_address
      return unless address

      "#{address.firstname} #{address.lastname}"
    end

    def can_ship?
      complete? || resumed? || awaiting_return? || returned?
    end

    def credit_cards
      credit_card_ids = payments.from_credit_card.pluck(:source_id).uniq
      CreditCard.where(id: credit_card_ids)
    end

    # Finalizes an in progress order after checkout is complete.
    # Called after transition to complete state when payments will have been processed
    def finalize!
      touch :completed_at

      all_adjustments.update_all state: 'closed'

      # update payment and shipment(s) states, and save
      updater.update_payment_state
      shipments.each do |shipment|
        shipment.update!(self)
        shipment.finalize!
      end

      updater.update_shipment_state
      updater.before_save_hook
      save

      deliver_order_confirmation_email

      state_changes.create(
        previous_state: 'cart',
        next_state: 'complete',
        name: 'order',
        user_id: user_id
      )
    end

    def deliver_order_confirmation_email
      return if subscription.present?

      Spree::OrderMailer.confirm_email_for_customer(id).deliver_later(wait: 10.seconds)
      Spree::OrderMailer.confirm_email_for_shop(id).deliver_later(wait: 10.seconds)
    end

    # Helper methods for checkout steps
    def paid?
      payment_state == 'paid' || payment_state == 'credit_owed'
    end

    # "Checkout" is the initial state and, for card payments, "pending" is the state after auth
    # These are both valid states to process the payment
    def pending_payments
      (payments.select(&:pending?) +
        payments.select(&:requires_authorization?) +
        payments.select(&:processing?) +
        payments.select(&:checkout?)).uniq
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
      process_each_payment(&:process!)
    rescue Core::GatewayError => e
      result = !!Spree::Config[:allow_checkout_on_gateway_error]
      errors.add(:base, e.message) && (return result)
    end

    def process_payments_offline!
      process_each_payment(&:process_offline!)
    rescue Core::GatewayError => e
      errors.add(:base, e.message)
      false
    end

    def products
      line_items.map(&:product)
    end

    def variants
      line_items.map(&:variant)
    end

    def insufficient_stock_lines
      line_items.select(&:insufficient_stock?)
    end

    def empty!
      line_items.destroy_all
      all_adjustments.destroy_all
      payments.clear
      shipments.destroy_all
      restart_checkout_flow if state.in?(["payment", "confirmation"])
    end

    def state_changed(name)
      state = "#{name}_state"
      return unless persisted?

      old_state = __send__("#{state}_was")
      state_changes.create(
        previous_state: old_state,
        next_state: __send__(state),
        name: name,
        user_id: user_id
      )
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

    # Clear shipments and move order back to address state unless compete. This is relevant where
    # an order is part-way through checkout and the user changes items in the cart; in that case
    # we need to reset the checkout flow to ensure the order is processed correctly.
    def ensure_updated_shipments
      if !completed? && shipments.any?
        shipments.destroy_all
        restart_checkout_flow
      end
    end

    def refresh_shipment_rates
      shipments.map(&:refresh_rates)
    end

    # Check that line_items in the current order are available from a newly selected distribution
    def products_available_from_new_distribution
      return if OrderCycleDistributedVariants.new(order_cycle, distributor)
        .distributes_order_variants?(self)

      errors.add(:base, I18n.t(:spree_order_availability_error))
    end

    def disallow_guest_order
      return unless using_guest_checkout? && registered_email?

      errors.add(:email, I18n.t('devise.failure.already_registered'))
    end

    # After changing line items of a completed order
    def update_shipping_fees!
      shipments.each do |shipment|
        next if shipment.shipped?

        update_adjustment! shipment.fee_adjustment if shipment.fee_adjustment
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
        report.add_metadata(:order, attributes)
        report.add_metadata(:shipment, shipment.attributes)
        report.add_metadata(:shipment_in_db, Spree::Shipment.find_by(id: shipment.id).attributes)
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

    def set_order_cycle!(order_cycle)
      return if self.order_cycle == order_cycle

      self.order_cycle = order_cycle
      self.distributor = nil unless order_cycle.nil? || order_cycle.has_distributor?(distributor)
      empty!
      save!
    end

    def cap_quantity_at_stock!
      line_items.includes(variant: :stock_items).find_each(&:cap_quantity_at_stock!)
    end

    def set_distributor!(distributor)
      self.distributor = distributor
      self.order_cycle = nil unless order_cycle&.has_distributor? distributor
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
      shipment_adjustments.reload.tax.sum(:amount)
    end

    def enterprise_fee_tax
      all_adjustments.tax.where(adjustable: all_adjustments.enterprise_fee).sum(:amount)
    end

    def total_tax
      additional_tax_total + included_tax_total
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

    def sorted_line_items
      if distributor.preferred_invoice_order_by_supplier
        line_items.sort_by { |li| [li.supplier.name, li.product.name] }
      else
        line_items.sort_by { |li| [li.product.name] }
      end
    end

    private

    def fee_handler
      @fee_handler ||= OrderFeesHandler.new(self)
    end

    def clear_legacy_taxes!
      # For instances that use additional taxes, old orders can have taxes recorded in
      # lump-sum amounts per-order. We clear them here before re-applying the order's taxes,
      # which will now be applied per-item.
      adjustments.legacy_tax.delete_all
    end

    def process_each_payment
      raise Core::GatewayError, Spree.t(:no_pending_payments) if pending_payments.empty?

      pending_payments.each do |payment|
        break if payment_total >= total

        yield payment

        if payment.completed?
          self.payment_total += payment.amount
        end
      end
    end

    def link_by_email
      self.email = user.email if user
    end

    # Determine if email is required (we don't want validation errors before we hit the checkout)
    def require_email
      return true unless (new_record? || cart?) && !checkout_processing
    end

    def ensure_line_items_present
      return if line_items.present?

      errors.add(:base, Spree.t(:there_are_no_items_for_this_order)) && (return false)
    end

    def ensure_available_shipping_rates
      return unless shipments.empty? || shipments.any? { |shipment| shipment.shipping_rates.blank? }

      errors.add(:base, Spree.t(:items_cannot_be_shipped)) && (return false)
    end

    def after_cancel
      shipments.each(&:cancel!)
      payments.checkout.each(&:void!)

      OrderMailer.cancel_email(id).deliver_later if send_cancellation_email
      update(payment_state: updater.update_payment_state)
    end

    def after_resume
      shipments.each(&:resume!)
      payments.void.each(&:resume!)

      update(payment_state: updater.update_payment_state)
    end

    def use_billing?
      @use_billing == true || @use_billing == 'true' || @use_billing == '1'
    end

    def set_currency
      self.currency = Spree::Config[:currency] if self[:currency].nil?
    end

    def using_guest_checkout?
      require_email && !user&.id
    end

    def registered_email?
      Spree::User.exists?(email: email)
    end

    def adjustments_fetcher
      @adjustments_fetcher ||= OrderAdjustmentsFetcher.new(self)
    end

    def skip_payment_for_subscription?
      subscription.present? && order_cycle.orders_close_at&.>(Time.zone.now)
    end

    def require_customer?
      persisted? && state != "cart"
    end

    def ensure_customer
      self.customer ||= CustomerSyncer.find_and_update_customer(self)
      self.customer ||= CustomerSyncer.create_customer(self) if require_customer?
    end

    def update_adjustment!(adjustment)
      return if adjustment.finalized?

      adjustment.update_adjustment!(force: true)
      updater.update_totals_and_states
    end
  end
end
