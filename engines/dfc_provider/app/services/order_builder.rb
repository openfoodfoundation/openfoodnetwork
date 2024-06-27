# frozen_string_literal: true

class OrderBuilder < DfcBuilder
  def self.build_anonymous(order)
    id = urls.anonymous_orders_url

    DataFoodConsortium::Connector::Order.new(
      id,
      orderStatus: 'complete'
    ).tap do |e|
      add_ofn_property(e, "ofn:producer_postcode", order.producer_postcode)
      add_ofn_property(e, "ofn:distributor_postcode", order.distributor_postcode)
      add_ofn_property(e, "ofn:variant_unit_name", order.unit_name)
      add_ofn_property(e, "ofn:variant_unit_type", order.unit_type)
      add_ofn_property(e, "ofn:variant_units", order.units)
      add_ofn_property(e, "ofn:price", order.price.to_f)
      add_ofn_property(e, "ofn:quantity_sold", order.quantity_sold)
    end
  end

  def self.add_ofn_property(dfc_enterprise, property_name, value)
    dfc_enterprise.registerSemanticProperty(property_name) { value }
  end
end
