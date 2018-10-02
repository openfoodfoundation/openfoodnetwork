class Api::Admin::OrderSerializer < ActiveModel::Serializer
  attributes :id, :number, :full_name, :email, :phone, :completed_at, :display_total
  attributes :show_path, :edit_path, :state, :payment_state, :shipment_state
  attributes :payments_path, :shipments_path, :ship_path, :ready_to_ship, :created_at
  attributes :distributor_name, :special_instructions, :payment_capture_path

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
    spree_routes_helper.admin_order_path(object)
  end

  def edit_path
    return '' unless object.id
    spree_routes_helper.edit_admin_order_path(object)
  end

  def payments_path
    return '' unless object.payment_state
    spree_routes_helper.admin_order_payments_path(object)
  end

  def shipments_path
    return '' unless object.shipment_state
    spree_routes_helper.admin_order_shipments_path(object)
  end

  def ship_path
    spree_routes_helper.fire_admin_order_path(object, e: 'ship')
  end

  def payment_capture_path
    pending_payment = object.pending_payments.first
    return '' unless object.payment_required? && pending_payment
    spree_routes_helper.fire_admin_order_payment_path(object, pending_payment.id, e: 'capture')
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

  private

  def spree_routes_helper
    Spree::Core::Engine.routes_url_helpers
  end
end
