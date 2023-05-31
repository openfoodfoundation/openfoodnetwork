# frozen_string_literal: true

require 'open_food_network/enterprise_injection_data'

module InjectionHelper
  include SerializerHelper
  include EnterprisesHelper
  include OrderCyclesHelper

  def inject_enterprises(enterprises = nil)
    inject_json_array(
      "enterprises",
      enterprises || default_enterprise_query,
      Api::EnterpriseSerializer,
      enterprise_injection_data
    )
  end

  def inject_groups
    select_only = required_attributes EnterpriseGroup, Api::GroupListSerializer

    inject_json_array(
      "groups",
      EnterpriseGroup.on_front_page.by_position.select(select_only).
        includes(enterprises: [:shipping_methods, { address: [:state, :country] }],
                 address: :state).
        all,
      Api::GroupListSerializer
    )
  end

  def inject_enterprise_shopfront(enterprise)
    inject_json(
      "shopfront",
      enterprise,
      Api::EnterpriseShopfrontSerializer
    )
  end

  def inject_enterprise_shopfront_list
    select_only = required_attributes Enterprise, Api::EnterpriseShopfrontListSerializer

    inject_json_array(
      "enterprises",
      Enterprise.activated.visible.select(select_only).includes(address: [:state, :country]).all,
      Api::EnterpriseShopfrontListSerializer
    )
  end

  def inject_enterprise_and_relatives
    enterprises_and_relatives = current_distributor.
      relatives_including_self.
      activated.
      includes(:properties, address: [:state, :country], supplied_products: :properties).
      all

    inject_json_array "enterprises",
                      enterprises_and_relatives,
                      Api::EnterpriseSerializer, enterprise_injection_data
  end

  def inject_group_enterprises
    inject_json_array(
      "enterprises",
      @group.enterprises.activated.visible.all,
      Api::EnterpriseSerializer,
      enterprise_injection_data
    )
  end

  def inject_current_hub
    inject_json "currentHub",
                current_distributor,
                Api::EnterpriseSerializer,
                enterprise_injection_data
  end

  def inject_current_order
    inject_json "currentOrder",
                current_order,
                Api::CurrentOrderSerializer,
                current_distributor: current_distributor,
                current_order_cycle: current_order_cycle
  end

  def inject_current_order_cycle
    serializer = Api::OrderCycleSerializer.new(current_order_cycle)
    json = serializer.object.present? ? serializer.to_json : "{}"
    render partial: "json/injection_ams", locals: { name: "orderCycleData", json: json }
  end

  def inject_taxons
    inject_json_array "taxons", Spree::Taxon.all.to_a, Api::TaxonSerializer
  end

  def inject_properties
    inject_json_array "properties", Spree::Property.all.to_a, Api::PropertySerializer
  end

  def inject_currency_config
    inject_json "currencyConfig", {}, Api::CurrencyConfigSerializer
  end

  def inject_open_street_map_config
    inject_json "openStreetMapConfig", {}, Api::OpenStreetMapConfigSerializer
  end

  def inject_spree_api_key
    render partial: "json/injection_ams",
           locals: { name: 'spreeApiKey', json: "'#{@spree_api_key}'" }
  end

  def inject_available_countries
    inject_json_array "availableCountries", available_countries, Api::CountrySerializer
  end

  def inject_enterprise_attributes
    render partial: "json/injection_ams",
           locals: { name: 'enterpriseAttributes', json: @enterprise_attributes.to_json.to_s }
  end

  def inject_orders
    inject_json_array "orders", @orders.all, Api::OrderSerializer
  end

  def inject_shops
    customers = spree_current_user.customers
    shops = Enterprise.where(id: @orders.pluck(:distributor_id).uniq |
                                 customers.pluck(:enterprise_id))
    inject_json_array "shops", shops.all, Api::ShopForOrdersSerializer
  end

  def inject_saved_credit_cards
    data = spree_current_user ? spree_current_user.credit_cards.with_payment_profile.all : []

    inject_json_array "savedCreditCards", data, Api::CreditCardSerializer
  end

  def inject_current_user
    inject_json "user", spree_current_user, Api::UserSerializer
  end

  def inject_rails_flash
    inject_json "railsFlash", OpenStruct.new(flash.to_hash), Api::RailsFlashSerializer
  end

  def inject_json_array(name, data, serializer, opts = {})
    opts = { each_serializer: serializer }.merge(opts)
    serializer = ActiveModel::ArraySerializer

    inject_json(name, data, serializer, opts)
  end

  def inject_json(name, data, serializer, opts = {})
    serializer_instance = serializer.new(data, opts)
    json = serializer_instance.to_json
    render partial: "json/injection_ams", locals: { name: name, json: json }
  end

  private

  def default_enterprise_query
    Enterprise.activated.includes(address: [:state, :country]).all
  end

  def enterprise_injection_data
    @enterprise_injection_data ||= OpenFoodNetwork::EnterpriseInjectionData.new
    { data: @enterprise_injection_data }
  end
end
