# frozen_string_literal: true

class Invoice < ApplicationRecord
  belongs_to :order, class_name: 'Spree::Order'
  serialize :data, Hash
  before_validation :serialize_order

  def presenter
    @presenter ||= Invoice::DataPresenter.new(self)
  end

  def serialize_order
    self.data ||= order.serialize_for_invoice
  end
end
