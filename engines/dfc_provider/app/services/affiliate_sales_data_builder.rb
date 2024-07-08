# frozen_string_literal: true

class AffiliateSalesDataBuilder < DfcBuilder
  def self.build(user)
    DataFoodConsortium::Connector::Person.new(
      urls.affiliate_sales_data_person_url(user.id),
      logo: nil,
      firstName: nil,
      lastName: nil,
      affiliatedOrganizations: user_enterprise(user.enterprises.first)
    )
  end

  def self.user_enterprise(enterprise)
    DataFoodConsortium::Connector::Enterprise.new(
      urls.enterprise_url(enterprise.id),
      name: enterprise.name
    )
  end

  def self.sales_data
    Spree::LineItem
      .joins(Arel.sql(joins_conditions))
      .select(Arel.sql(select_fields))
      .where(where_conditions)
      .group(Arel.sql(group_fields))
      .order(Arel.sql(order_fields))
  end

  def self.joins_conditions
    [
      "JOIN spree_orders ON spree_orders.id = spree_line_items.order_id",
      "JOIN spree_variants ON spree_variants.id = spree_line_items.variant_id",
      "JOIN spree_products ON spree_products.id = spree_variants.product_id",
      "JOIN enterprises AS enterprise1 ON spree_orders.distributor_id = enterprise1.id",
      "JOIN enterprises AS enterprise2 ON spree_products.supplier_id = enterprise2.id",
      "JOIN spree_addresses AS distributors ON enterprise1.address_id = distributors.id",
      "JOIN spree_addresses AS producers ON enterprise2.address_id = producers.id"
    ].join(' ')
  end

  def self.select_fields
    "spree_products.name AS product_name,
     spree_variants.display_name AS unit_name,
     spree_products.variant_unit AS unit_type,
     spree_variants.unit_value AS units,
     spree_variants.unit_presentation,
     SUM(spree_line_items.quantity) AS quantity_sold,
     spree_line_items.price,
     distributors.zipcode AS distributor_postcode,
     producers.zipcode AS producer_postcode"
  end

  def self.where_conditions
    { spree_orders: { state: 'complete' } }
  end

  def self.group_fields
    'spree_products.name,
     spree_variants.display_name,
     spree_variants.unit_value,
     spree_variants.unit_presentation,
     spree_products.variant_unit,
     spree_line_items.price,
     distributors.zipcode,
     producers.zipcode'
  end

  def self.order_fields
    'spree_products.name'
  end

  private_class_method :sales_data
end
