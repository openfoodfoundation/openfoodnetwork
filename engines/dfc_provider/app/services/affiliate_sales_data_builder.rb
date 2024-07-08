# frozen_string_literal: true

class AffiliateSalesDataBuilder < DfcBuilder
  def self.build_person(user)
    DataFoodConsortium::Connector::Person.new(
      urls.affiliate_sales_data_person_url(user.id),
      logo: nil,
      firstName: nil,
      lastName: nil,
      affiliatedOrganizations: user_enterprises(user.enterprises)
    )
  end

  def self.user_enterprises(enterprises)
    enterprises.map do |enterprise|
      DataFoodConsortium::Connector::Enterprise.new(urls.enterprise_url(enterprise.id))
    end
  end

  # def self.build_producers
  #   sales_data.uniq.map do |sale|
  #     DataFoodConsortium::Connector::Enterprise.new(
  #       urls.enterprise_url(sale.producer_id),
  #       name: nil,
  #       logo: nil,
  #       description: nil,
  #       vatNumber: nil
  #     )
  #   end
  # end

  def self.build_orders
    sales_data.map do |sale|
      DataFoodConsortium::Connector::Order.new(
        urls.enterprise_order_url(sale.producer_id, sale.order_id),
        number: nil,
        date: sale.order_date.strftime("%Y-%m-%d"),
        saleSession: DataFoodConsortium::Connector::SaleSession.new(
          urls.enterprise_sale_session_url(sale.producer_id, sale.order_id),
          beginDate: nil,
          endDate: nil,
          quantity: nil
        )
      )
    end
  end

  def self.build_sales_session
    sales_data.map do |sale|
      DataFoodConsortium::Connector::SaleSession.new(
        urls.enterprise_sale_session_url(sale.producer_id, sale.order_id),
        beginDate: nil,
        endDate: nil,
        quantity: nil
      )
    end
  end

  def self.sales_data
    @sales_data ||=
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
    "spree_orders.id AS order_id,
     spree_orders.created_at AS order_date,
     spree_products.name AS product_name,
     spree_variants.display_name AS unit_name,
     spree_products.variant_unit AS unit_type,
     spree_variants.unit_value AS units,
     spree_variants.unit_presentation,
     SUM(spree_line_items.quantity) AS quantity_sold,
     spree_line_items.price,
     producers.id AS producer_id,
     distributors.id AS distributor_id,
     distributors.zipcode AS distributor_postcode,
     producers.zipcode AS producer_postcode"
  end

  def self.where_conditions
    { spree_orders: { state: 'complete' } }
  end

  def self.group_fields
    'spree_orders.id,
     spree_products.name,
     spree_variants.display_name,
     spree_variants.unit_value,
     spree_variants.unit_presentation,
     spree_products.variant_unit,
     spree_line_items.price,
     producers.id,
     distributors.id,
     distributors.zipcode,
     producers.zipcode'
  end

  def self.order_fields
    'spree_products.name'
  end
end
