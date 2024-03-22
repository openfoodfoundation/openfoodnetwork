# frozen_string_literal: true

module Admin
  module InjectionHelper
    def admin_inject_enterprise(enterprise)
      admin_inject_json_ams "admin.enterprises",
                            "enterprise",
                            enterprise,
                            Api::Admin::EnterpriseSerializer
    end

    def admin_inject_enterprises(my_enterprises, all_enterprises)
      admin_inject_json_ams_array("ofn.admin",
                                  "my_enterprises",
                                  my_enterprises,
                                  Api::Admin::BasicEnterpriseSerializer) +
        admin_inject_json_ams_array("ofn.admin",
                                    "all_enterprises",
                                    all_enterprises,
                                    Api::Admin::BasicEnterpriseSerializer)
    end

    def admin_inject_enterprise_relationships(enterprise_relationships)
      admin_inject_json_ams_array "ofn.admin",
                                  "enterprise_relationships",
                                  enterprise_relationships,
                                  Api::Admin::EnterpriseRelationshipSerializer
    end

    def admin_inject_payment_methods(payment_methods)
      admin_inject_json_ams_array "admin.paymentMethods",
                                  "paymentMethods",
                                  payment_methods,
                                  Api::Admin::IdNameSerializer
    end

    def admin_inject_payment_method(payment_method)
      admin_inject_json_ams "admin.paymentMethods",
                            "paymentMethod",
                            payment_method,
                            Api::Admin::PaymentMethodSerializer
    end

    def admin_inject_shipping_methods(shipping_methods)
      admin_inject_json_ams_array "admin.shippingMethods",
                                  "shippingMethods",
                                  shipping_methods,
                                  Api::Admin::IdNameSerializer
    end

    def admin_inject_shipping_method(shipping_method)
      admin_inject_json_ams "admin.shippingMethods",
                            "shippingMethod",
                            shipping_method,
                            Api::Admin::ShippingMethodSerializer
    end

    def admin_inject_shops(shops, opts = {})
      opts.reverse_merge!(module: 'admin.customers')
      admin_inject_json_ams_array opts[:module],
                                  "shops",
                                  shops,
                                  Api::Admin::IdNameSerializer
    end

    def admin_inject_available_countries(opts = {})
      opts.reverse_merge!(module: 'admin.customers')
      admin_inject_json_ams_array opts[:module],
                                  'availableCountries',
                                  available_countries,
                                  Api::CountrySerializer
    end

    def admin_inject_hubs(hubs, opts = {})
      opts.reverse_merge!(module: 'ofn.admin')
      admin_inject_json_ams_array opts[:module],
                                  "hubs",
                                  hubs,
                                  Api::Admin::IdNameSerializer
    end

    def admin_inject_producers(producers, opts = {})
      opts.reverse_merge!(module: 'ofn.admin')
      admin_inject_json_ams_array opts[:module],
                                  "producers",
                                  producers,
                                  Api::Admin::IdNameSerializer
    end

    def admin_inject_inventory_items(inventory_items, opts = { module: 'ofn.admin' })
      admin_inject_json_ams_array opts[:module],
                                  "inventoryItems",
                                  inventory_items,
                                  Api::Admin::InventoryItemSerializer
    end

    def admin_inject_column_preferences(opts = {})
      opts.reverse_merge!(module: 'ofn.admin', action: "#{controller_name}_#{action_name}")
      column_preferences = ColumnPreference.for(spree_current_user, opts[:action])
      admin_inject_json_ams_array opts[:module],
                                  "columns",
                                  column_preferences,
                                  Api::Admin::ColumnPreferenceSerializer
    end

    def admin_inject_currency_config
      admin_inject_json_ams 'admin.utils',
                            "currencyConfig",
                            {},
                            Api::CurrencyConfigSerializer
    end

    def admin_inject_hub_permissions(hub_permissions)
      render partial: "admin/json/injection_ams", locals: { ngModule: "admin.variantOverrides",
                                                            name: "hubPermissions",
                                                            json: hub_permissions.to_json }
    end

    def admin_inject_tax_categories(tax_categories, opts = { module: 'ofn.admin' })
      admin_inject_json_ams_array opts[:module],
                                  "tax_categories",
                                  tax_categories,
                                  Api::Admin::TaxCategorySerializer
    end

    def admin_inject_taxons(taxons)
      admin_inject_json_ams_array "admin.taxons",
                                  "taxons",
                                  taxons,
                                  Api::Admin::TaxonSerializer
    end

    def admin_inject_variant_overrides(variant_overrides)
      admin_inject_json_ams_array "admin.variantOverrides",
                                  "variantOverrides",
                                  variant_overrides,
                                  Api::Admin::VariantOverrideSerializer
    end

    def admin_inject_order_cycle_instance(order_cycle)
      render partial: "admin/json/injection_ams",
             locals: { ngModule: 'admin.orderCycles',
                       name: 'ocInstance',
                       json: "{coordinator_id: '#{order_cycle.coordinator.id}'}" }
    end

    def admin_inject_order_cycles(order_cycles)
      admin_inject_json_ams_array "admin.orders",
                                  "orderCycles",
                                  order_cycles,
                                  Api::Admin::BasicOrderCycleSerializer,
                                  current_user: spree_current_user
    end

    def admin_inject_spree_api_key(spree_api_key)
      render partial: "admin/json/injection_ams",
             locals: { ngModule: 'admin.indexUtils',
                       name: 'SpreeApiKey',
                       json: "'#{spree_api_key}'" }
    end

    def admin_inject_available_units
      admin_inject_json "admin.products",
                        "availableUnits",
                        CurrentConfig.get(:available_units)
    end

    def admin_inject_json(ng_module, name, data)
      json = data.to_json
      render partial: "admin/json/injection_ams",
             locals: { ngModule: ng_module,
                       name:,
                       json: }
    end

    def admin_inject_json_ams(ng_module, name, data, serializer, opts = {})
      json = serializer.new(data, { scope: spree_current_user }.merge(opts)).to_json
      render partial: "admin/json/injection_ams",
             locals: { ngModule: ng_module,
                       name:,
                       json: }
    end

    def admin_inject_json_ams_array(ng_module, name, data, serializer, opts = {})
      json = ActiveModel::ArraySerializer.
        new(data, { each_serializer: serializer, scope: spree_current_user }.merge(opts)).to_json

      render partial: "admin/json/injection_ams",
             locals: { ngModule: ng_module,
                       name:,
                       json: }
    end
  end
end
