# frozen_string_literal: true

module Spree
  class Property < ApplicationRecord
    has_many :product_properties, dependent: :destroy
    has_many :products, through: :product_properties
    has_many :producer_properties, dependent: :destroy

    after_touch :touch_producer_properties

    validates :name, :presentation, presence: true

    scope :sorted, -> { order(:name) }

    # Properties of products distributed by the enterprise in any order cycle, including the
    # properties of their producers when the products inherit them.
    scope :distributed_by, lambda { |distributor|
      variants = Spree::Variant.joins(:exchanges)
        .merge(Exchange.outgoing).merge(Exchange.to_enterprise(distributor))
      product_property_ids = Spree::ProductProperty
        .where(product_id: variants.select(:product_id)).select(:property_id)
      producer_ids = variants.joins(:product)
        .where(spree_products: { inherits_properties: true }).select(:enterprise_id)
      producer_property_ids = ProducerProperty.where(producer_id: producer_ids).select(:property_id)

      where(id: product_property_ids).or(where(id: producer_property_ids))
    }

    def property
      self
    end

    private

    def touch_producer_properties
      producer_properties.each(&:touch)
    end
  end
end
