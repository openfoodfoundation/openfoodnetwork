require 'open_food_network/enterprise_injection_data'

module InjectionHelper
  def inject_enterprises
    inject_json_ams "enterprises", Enterprise.activated.includes(address: :state).all, Api::EnterpriseSerializer, enterprise_injection_data
  end

  def inject_enterprise_and_relatives
    inject_json_ams "enterprises", current_distributor.relatives_including_self.activated.includes(address: :state).all, Api::EnterpriseSerializer, enterprise_injection_data
  end

  def inject_shop_enterprises
    ocs = if current_order_cycle
            [current_order_cycle]
          else
            OrderCycle.not_closed.with_distributor(current_distributor)
          end
    inject_json_ams "enterprises", current_distributor.plus_relatives_and_oc_producers(ocs).activated.includes(address: :state).all, Api::EnterpriseSerializer, enterprise_injection_data
  end

  def inject_group_enterprises
    inject_json_ams "group_enterprises", @group.enterprises.activated.all, Api::EnterpriseSerializer, enterprise_injection_data
  end

  def inject_current_hub
    inject_json_ams "currentHub", current_distributor, Api::EnterpriseSerializer, enterprise_injection_data
  end

  def inject_current_order
    inject_json_ams "currentOrder", current_order, Api::CurrentOrderSerializer, current_distributor: current_distributor, current_order_cycle: current_order_cycle
  end

  def inject_available_shipping_methods
    inject_json_ams "shippingMethods", available_shipping_methods,
      Api::ShippingMethodSerializer, current_order: current_order
  end

  def inject_available_payment_methods
    inject_json_ams "paymentMethods", available_payment_methods,
      Api::PaymentMethodSerializer, current_order: current_order
  end

  def inject_taxons
    inject_json_ams "taxons", Spree::Taxon.all, Api::TaxonSerializer
  end

  def inject_properties
    inject_json_ams "properties", Spree::Property.all, Api::PropertySerializer
  end

  def inject_currency_config
    inject_json_ams "currencyConfig", {}, Api::CurrencyConfigSerializer
  end

  def inject_spree_api_key
    render partial: "json/injection_ams", locals: {name: 'spreeApiKey', json: "'#{@spree_api_key.to_s}'"}
  end

  def inject_available_countries
    inject_json_ams "availableCountries", available_countries, Api::CountrySerializer
  end

  def inject_enterprise_attributes
    render partial: "json/injection_ams", locals: {name: 'enterpriseAttributes', json: "#{@enterprise_attributes.to_json}"}
  end

  def inject_orders_by_distributor
    data_array = spree_current_user.orders_by_distributor
    inject_json_ams "orders_by_distributor", data_array, Api::OrdersByDistributorSerializer
  end

  def inject_saved_credit_cards
    if spree_current_user
      inject_json_ams "savedCreditCards", spree_current_user.credit_cards, Api::CreditCardSerializer
    end
  end

  def inject_json(name, partial, opts = {})
    render partial: "json/injection", locals: {name: name, partial: partial}.merge(opts)
  end

  def inject_json_ams(name, data, serializer, opts = {})
    if data.is_a?(Array)
      json = ActiveModel::ArraySerializer.new(data, {each_serializer: serializer}.merge(opts)).to_json
    else
      json = serializer.new(data, opts).to_json
    end
    render partial: "json/injection_ams", locals: {name: name, json: json}
  end


  private

  def enterprise_injection_data
    @enterprise_injection_data ||= OpenFoodNetwork::EnterpriseInjectionData.new
    {data: @enterprise_injection_data}
  end

end
