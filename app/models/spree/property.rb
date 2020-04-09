module Spree
  class Property < ActiveRecord::Base
    has_many :product_properties, dependent: :destroy
    has_many :products, through: :product_properties
    has_many :producer_properties

    attr_accessible :name, :presentation

    validates :name, :presentation, presence: true

    scope :sorted, -> { order(:name) }

    scope :applied_by, ->(enterprise) {
      select('DISTINCT spree_properties.*').
        joins(:product_properties).
        where('spree_product_properties.product_id IN (?)', enterprise.supplied_product_ids)
    }

    scope :ever_sold_by, ->(shop) {
      joins(products: { variants: { exchanges: :order_cycle } }).
        merge(Exchange.outgoing).
        merge(Exchange.to_enterprise(shop)).
        select('DISTINCT spree_properties.*')
    }

    scope :currently_sold_by, ->(shop) {
      ever_sold_by(shop).
        merge(OrderCycle.active)
    }

    def property
      self
    end
  end
end
