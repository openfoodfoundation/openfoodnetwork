class ProducerProperty < ActiveRecord::Base
  belongs_to :producer, class_name: 'Enterprise', touch: true
  belongs_to :property, class_name: 'Spree::Property'

  default_scope order("#{table_name}.position")

  scope :ever_sold_by, ->(shop) {
    joins(producer: { supplied_products: { variants: { exchanges: :order_cycle } } }).
      merge(Exchange.outgoing).
      merge(Exchange.to_enterprise(shop)).
      select('DISTINCT producer_properties.*')
  }

  scope :currently_sold_by, ->(shop) {
    ever_sold_by(shop).
      merge(OrderCycle.active)
  }

  def property_name
    property.name if property
  end

  def property_name=(name)
    if name.present?
      self.property = Spree::Property.find_by_name(name) ||
                      Spree::Property.create(name: name, presentation: name)
    end
  end
end
