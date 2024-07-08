# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class AffiliateSalesDataBuilder < DfcBuilder
  class << self
    def build_person(user)
      DataFoodConsortium::Connector::Person.new(
        urls.affiliate_sales_data_person_url(user.id),
        logo: nil,
        firstName: nil,
        lastName: nil,
        affiliatedOrganizations: user_enterprises(user.enterprises)
      )
    end

    def user_enterprises(enterprises)
      enterprises.map { |enterprise| build_enterprise(enterprise.id) }
    end

    def build_addresses
      sales_data
        .uniq { |sale| sale.producer_city && sale.producer_postcode }
        .map { |sale| build_address(sale) }
    end

    def build_producers
      sales_data
        .uniq(&:producer_id)
        .map { |sale| build_producer(sale) }
    end

    def build_supplied_products
      sales_data
        .uniq(&:producer_id)
        .map { |sale| build_supplied_product(sale) }
    end

    def build_catalogue_items
      sales_data
        .uniq(&:producer_id)
        .map { |sale| build_catalogue_item(sale) }
    end

    def build_offers
      sales_data
        .uniq(&:producer_id)
        .map { |sale| build_offer(sale) }
    end

    def build_order_lines
      sales_data.map { |sale| build_order_line(sale) }
    end

    def build_orders
      sales_data.map { |sale| build_order(sale) }
    end

    # def build_sale_sessions
    #   sales_data.map { |sale| build_sale_session(sale) }
    # end

    private

    def build_enterprise(id)
      DataFoodConsortium::Connector::Enterprise.new(urls.enterprise_url(id))
    end

    def build_address(sale)
      DataFoodConsortium::Connector::Address.new(
        urls.address_url(sale.producer_id),
        postalCode: sale.producer_postcode,
        country: nil,
        latitude: nil,
        longitude: nil,
        region: nil,
        street: nil,
        city: sale.producer_city
      )
    end

    def build_producer(sale)
      DataFoodConsortium::Connector::Enterprise.new(
        urls.enterprise_url(sale.producer_id),
        logo: nil,
        name: nil,
        description: nil,
        vatNumber: nil,
        suppliedProducts: build_supplied_product(sale),
        localizations: build_address(sale)
      )
    end

    def build_supplied_product(sale)
      DataFoodConsortium::Connector::SuppliedProduct.new(
        urls.enterprise_supplied_product_url(sale.producer_id, sale.product_id),
        name: sale.product_name,
        description: nil,
        alcoholPercentage: nil,
        lifetime: nil,
        usageOrStorageConditions: nil,
        totalTheoreticalStock: nil,
        catalogItems: build_catalogue_item(sale),
        quantity: build_quantity(sale)
      )
    end

    def build_catalogue_item(sale)
      DataFoodConsortium::Connector::CatalogItem.new(
        urls.enterprise_catalog_item_url(sale.producer_id, sale.product_id),
        offers: build_offer(sale)
      )
    end

    def build_offer(sale)
      DataFoodConsortium::Connector::Offer.new(
        urls.enterprise_offer_url(sale.producer_id, sale.product_id)
      )
    end

    def build_order_line(sale)
      DataFoodConsortium::Connector::OrderLine.new(
        urls.enterprise_order_order_line_url(sale.producer_id, sale.order_id, sale.line_item_id),
        description: nil,
        order: build_order(sale),
        quantity: build_quantity(sale),
        price: build_price(sale)
      )
    end

    def build_order(sale)
      DataFoodConsortium::Connector::Order.new(
        urls.enterprise_order_url(sale.producer_id, sale.order_id),
        number: nil,
        date: sale.order_date.strftime("%Y-%m-%d")
        # saleSession: build_sale_session(sale)
      )
    end

    def build_sale_session(sale)
      DataFoodConsortium::Connector::SaleSession.new(
        urls.enterprise_sale_session_url(sale.producer_id, sale.line_item_id),
        beginDate: nil,
        endDate: nil,
        quantity: nil
      )
    end

    def build_quantity(sale)
      DataFoodConsortium::Connector::Quantity.new(
        unit: sale.unit_presentation,
        value: sale.line_item_quantity
      )
    end

    def build_price(sale)
      DataFoodConsortium::Connector::Price.new(
        value: sale.price.to_f,
        unit: sale.currency
      )
    end

    def sales_data
      @sales_data ||= AffiliateSalesQuery.call
    end
  end
end
# rubocop:enable Metrics/ClassLength
