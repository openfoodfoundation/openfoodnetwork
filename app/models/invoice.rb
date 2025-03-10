# frozen_string_literal: true

class Invoice < ApplicationRecord
  self.belongs_to_required_by_default = false

  belongs_to :order, class_name: 'Spree::Order'
  serialize :data, Hash, coder: YAML
  before_validation :serialize_order
  after_create :cancel_previous_invoices
  default_scope { order(created_at: :desc) }

  def self.latest
    reorder(created_at: :desc).first
  end

  def presenter
    @presenter ||= Invoice::DataPresenter.new(self)
  end

  def serialize_order
    return data unless data.empty?

    self.data = Invoice::OrderSerializer.new(order).serializable_hash
  end

  def cancel_previous_invoices
    order.invoices.where.not(id:).update_all(cancelled: true)
  end

  def display_number
    "#{order.distributor.id}-#{number}"
  end

  def previous_invoice
    order.invoices.where(id: ...id).first
  end
end
