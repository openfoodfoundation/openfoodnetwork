class Api::Admin::OrderSerializer < ActiveModel::Serializer
  attributes :id, :number, :full_name, :email, :phone, :completed_at, :display_total
  attributes :show_path, :edit_path, :state, :payment_state, :shipment_state
  attributes :payments_path, :shipments_path, :ship_path, :ready_to_ship, :created_at
  attributes :distributor_name, :special_instructions, :pending_payments, :capture_path

  has_one :distributor, serializer: Api::Admin::IdSerializer
  has_one :order_cycle, serializer: Api::Admin::IdSerializer

  def full_name
    object.billing_address.nil? ? "" : ( object.billing_address.full_name || "" )
  end

  def distributor_name
    object.distributor.andand.name
  end

  def show_path
    return '' unless object.id
    Spree::Core::Engine.routes_url_helpers.admin_order_path(object)
  end

  def edit_path
    return '' unless object.id
    Spree::Core::Engine.routes_url_helpers.edit_admin_order_path(object)
  end

  def payments_path
    return '' unless object.payment_state
    Spree::Core::Engine.routes_url_helpers.admin_order_payments_path(object)
  end

  def shipments_path
    return '' unless object.shipment_state
    Spree::Core::Engine.routes_url_helpers.admin_order_shipments_path(object)
  end

  def ship_path
    Spree::Core::Engine.routes_url_helpers.fire_admin_order_path(object, e: 'ship')
  end

  def capture_path
    return '' unless ready_for_payment?
    return unless payment_to_capture
    Spree::Core::Engine.routes_url_helpers.fire_admin_order_payment_path(object, payment_to_capture.id, e: 'capture')
  end

  def ready_to_ship
    object.ready_to_ship?
  end

  def display_total
    object.display_total.to_html
  end

  def email
    object.email || ""
  end

  def phone
    object.billing_address.nil? ? "a" : ( object.billing_address.phone || "" )
  end

  def created_at
    object.created_at.blank? ? "" : I18n.l(object.created_at, format: '%B %d, %Y')
  end

  def completed_at
    object.completed_at.blank? ? "" : I18n.l(object.completed_at, format: '%B %d, %Y')
  end

  def pending_payments
    return if object.payments.blank?
    payment = object.payments.select{ |p| p if p.state == 'checkout' }.first
    return unless can_be_captured? payment

    payment.id
  end

  private

  def ready_for_payment?
    object.payment_required? && object.payments.present?
  end

  def payment_to_capture
    object.payments.select{ |p| p if p.state == 'checkout' }.first
  end

  def can_be_captured?(payment)
    payment && payment.actions.include?('capture')
  end
end
