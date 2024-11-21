# frozen_string_literal: true

module Spree
  class Order < ApplicationRecord
    include OrderShipment
    include OrderValidations
    include Checkout
    include Balance
    include SetUnusedAddressFields

    searchable_attributes :number, :state, :shipment_state, :payment_state, :distributor_id,
                          :order_cycle_id, :email, :total, :customer_id
    searchable_associations :shipping_method, :bill_address, :distributor
    searchable_scopes :complete, :incomplete, :sort_by_billing_address_name_asc,
                      :sort_by_billing_address_name_desc

    checkout_flow do
      go_to_state :address
      go_to_state :delivery
      go_to_state :payment, if: ->(order) {
        order.update_totals
        order.payment_required? || order.zero_priced_order?
      }
      go_to_state :confirmation
      go_to_state :complete
    end

    attr_accessor :use_billing, :checkout_processing, :save_bill_address,
                  :save_ship_address
    attr_writer :send_shipment_email

    token_resource

    belongs_to :user, class_name: "Spree::User", optional: true
    belongs_to :created_by, class_name: "Spree::User", optional: true

    belongs_to :bill_address, class_name: 'Spree::Address', optional: true
    alias_attribute :billing_address, :bill_address

    belongs_to :ship_address, class_name: 'Spree::Address', optional: true
    alias_attribute :shipping_address, :ship_address

    has_many :state_changes, as: :stateful, dependent: :destroy
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
    has_many :voucher_adjustments,
             -> {
               where(originator_type: 'Voucher')
                 .order("#{Spree::Adjustment.table_name}.created_at ASC")
             },
             class_name: 'Spree::Adjustment',
             dependent: :destroy
    has_many :invoices, dependent: :restrict_with_exception
    belongs_to :order_cycle, optional: true
    has_one :exchange, ->(order) {
      outgoing.to_enterprise(order.distributor)
    }, through: :order_cycle, source: :exchanges
    has_many :semantic_links, through: :exchange

    belongs_to :distributor, class_name: 'Enterprise', optional: true
    belongs_to :customer, optional: true
    has_one :proxy_order, dependent: :destroy
    has_one :subscription, through: :proxy_order

    accepts_nested_attributes_for :line_items
    accepts_nested_attributes_for :bill_address
    accepts_nested_attributes_for :ship_address
    accepts_nested_attributes_for :payments
    accepts_nested_attributes_for :shipments

    delegate :admin_and_handling_total, :payment_fee, :ship_total, to: :adjustments_fetcher
    delegate :update_totals, :update_totals_and_states, to: :updater
    delegate :create_line_item_fees!, :create_order_fees!, :update_order_fees!,
             :update_line_item_fees!, :recreate_all_fees!, to: :fee_handler

    validates :customer, presence: true, if: :require_customer?
    validate :products_available_from_new_distribution, if: lambda {
      distributor_id_changed? || order_cycle_id_changed?
    }
    validate :disallow_guest_order
    validates :email, presence: true,
                      format: /\A([\w.%+\-']+)@([\w\-]+\.)+(\w{2,})\z/i,
                      if: :require_email

    validates :order_cycle, presence: true, on: :require_distribution
    validates :distributor, presence: true, on: :require_distribution

    before_validation :set_currency
    before_validation :generate_order_number, if: :new_record?
    before_validation :clone_billing_address, if: :use_billing?
    before_validation :ensure_customer

    before_save :update_shipping_fees!, if: :complete?
    before_save :update_payment_fees!, if: :complete?
    before_create :link_by_email

    after_create :create_tax_charge!
    after_save :reapply_tax_on_changed_address

    after_save_commit DefaultAddressUpdater

    make_permalink field: :number

    attribute :send_cancellation_email, type: :boolean, default: true
    attribute :restock_items, type: :boolean, default: true

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
        where(spree_orders: { distributor_id: user.enterprises.select(&:id) })
      end
    }

    scope :sort_by_billing_address_name_asc, -> {
      references(:bill_address)
        .order("spree_addresses.lastname ASC, spree_addresses.firstname ASC")
    }

    scope :sort_by_billing_address_name_desc, -> {
      references(:bill_address)
        .order("spree_addresses.lastname DESC, spree_addresses.firstname DESC")
    }

    scope :with_line_items_variants_and_products_outer, lambda {
      left_outer_joins(line_items: { variant: :product })
    }

    # All the states an order can be in after completing the checkout
    FINALIZED_STATES = %w(complete canceled resumed awaiting_return returned).freeze

    scope :finalized, -> { where(state: FINALIZED_STATES) }
    scope :complete, -> { where.not(completed_at: nil) }
    scope :incomplete, -> { where(completed_at: nil) }
    scope :invoiceable, -> { where(state: [:complete, :resumed]) }
    scope :by_state, lambda { |state| where(state:) }
    scope :not_state, lambda { |state| where.not(state:) }

    def initialize(*_args)
      @checkout_processing = nil
      @manual_shipping_selection = nil

      super
    end

    # For compatiblity with Calculator::PriceSack
    def amount
      line_items.inject(0.0) { |sum, li| sum + li.amount }
    end

    # Order total without any applied discounts from vouchers
    def pre_discount_total
      item_total + all_adjustments.additional.eligible.non_voucher.sum(:amount)
    end

    def currency
      self[:currency] || CurrentConfig.get(:currency)
    end

    def display_item_total
      Spree::Money.new(item_total, currency:)
    end

    def display_adjustment_total
      Spree::Money.new(adjustment_total, currency:)
    end

    def display_total
      Spree::Money.new(total, currency:)
    end

    def display_payment_total
      Spree::Money.new(payment_total, currency:)
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
      !!(complete? &&
         !shipped? &&
         distributor&.allow_order_changes? &&
         order_cycle&.open?)
    end

    # Is this a free order in which case the payment step should be skipped
    # This allows unpaid subscription orders to be completed.
    #   Subscriptions place orders at the beginning of an order cycle. They need to
    #   be completed to draw from stock levels and trigger emails.
    def payment_required?
      total.to_f > 0.0 && !skip_payment_for_subscription?
    end

    # There are items present in the order, but either the items have zero price,
    # or the order's total has been modified (maybe discounted) to zero.
    def zero_priced_order?
      line_items.count.positive? && total.zero?
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
      self.class.unscoped.where(id:).update_all(email: user.email,
                                                user_id: user.id,
                                                created_by_id:)
    end

    def generate_order_number
      return if number.present?

      record = true
      while record
        random = "R#{Array.new(9){ rand(9) }.join}"
        record = self.class.find_by(number: random)
      end
      self.number = random if number.blank?
      number
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
      return if before_payment_state?

      clear_legacy_taxes!

      Spree::TaxRate.adjust(self, line_items)
      Spree::TaxRate.adjust(self, shipments) if shipments.any?
      Spree::TaxRate.adjust(self, adjustments.admin) if adjustments.admin.any?
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

    def can_show_invoice?
      complete? || resumed? || canceled?
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
      updater.shipping_address_from_distributor
      save

      deliver_order_confirmation_email

      BackorderJob.check_stock(self)

      state_changes.create(
        previous_state: 'cart',
        next_state: 'complete',
        name: 'order',
        user_id:
      )
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
      return unless !completed? && shipments.any?

      shipments.destroy_all
      restart_checkout_flow
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

    def before_payment_state?
      state.in?(["cart", "address", "delivery"])
    end

    def after_delivery_state?
      state.in?(["payment", "confirmation"])
    end

    def send_shipment_email
      return true if @send_shipment_email.nil?

      @send_shipment_email
    end

    # @return [BigDecimal] The rate of the voucher if applied to the order
    def applied_voucher_rate
      # As an order can have only one voucher,
      # hence using +take+ as each voucher adjustment will have the same voucher
      return BigDecimal(0) unless (voucher_adjustment = voucher_adjustments.take)

      voucher = voucher_adjustment.originator
      voucher.rate(self)
    end

    private

    def reapply_tax_on_changed_address
      return if before_payment_state?
      return unless tax_address&.saved_changes?

      create_tax_charge!
      update_totals_and_states
    end

    def deliver_order_confirmation_email
      return if subscription.present?

      Spree::OrderMailer.confirm_email_for_customer(id).deliver_later(wait: 10.seconds)
      Spree::OrderMailer.confirm_email_for_shop(id).deliver_later(wait: 10.seconds)
    end

    def fee_handler
      @fee_handler ||= Orders::HandleFeesService.new(self)
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
        if payment.amount.zero? && zero_priced_order?
          payment.update_columns(state: "completed", captured_at: Time.zone.now)
        end

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

    def use_billing?
      @use_billing == true || @use_billing == 'true' || @use_billing == '1'
    end

    def set_currency
      self.currency = CurrentConfig.get(:currency) if self[:currency].nil?
    end

    def using_guest_checkout?
      require_email && !user&.id
    end

    def registered_email?
      Spree::User.where(email:).exists?
    end

    def adjustments_fetcher
      @adjustments_fetcher ||= Orders::FetchAdjustmentsService.new(self)
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
      update_totals_and_states
    end
  end
end
