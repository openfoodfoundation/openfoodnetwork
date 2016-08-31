module OpenFoodNetwork
  module ColumnPreferenceDefaults

    private

    # NOTE: These methods define valid column names (via hash keys)
    # as well as default values for column attributes (eg. visiblity)
    # Default values can be overridden by storing a different value
    # for a given user, action_name and column_name

    def variant_overrides_index_columns
      node = 'admin.variant_overrides.index'
      {
        producer:     { name: I18n.t("admin.producer"),         visible: true },
        product:      { name: I18n.t("admin.product"),          visible: true },
        sku:          { name: I18n.t("admin.sku"),              visible: false },
        price:        { name: I18n.t("admin.price"),            visible: true },
        on_hand:      { name: I18n.t("admin.on_hand"),          visible: true },
        on_demand:    { name: I18n.t("admin.on_demand?"),       visible: true },
        reset:        { name: I18n.t("#{node}.enable_reset?"),  visible: false },
        inheritance:  { name: I18n.t("#{node}.inherit?"),       visible: false },
        tags:         { name: I18n.t("admin.tags"),             visible: false },
        visibility:   { name: I18n.t("#{node}.hide"),           visible: false }
      }
    end

    def customers_index_columns
      node = 'admin.customers.index'
      {
        email:          { name: I18n.t("admin.email"),          visible: true },
        name:           { name: I18n.t("admin.name"),           visible: true },
        code:           { name: I18n.t("#{node}.code"),         visible: true },
        tags:           { name: I18n.t("admin.tags"),           visible: true },
        bill_address:   { name: I18n.t("#{node}.bill_address"), visible: true },
        ship_address:   { name: I18n.t("#{node}.ship_address"), visible: true }
      }
    end

    def orders_bulk_management_columns
      node = "admin.orders.bulk_management"
      {
        order_no:               { name: I18n.t("#{node}.order_no"),       visible: false },
        full_name:              { name: I18n.t("admin.name"),             visible: true },
        email:                  { name: I18n.t("admin.email"),            visible: false },
        phone:                  { name: I18n.t("admin.phone"),            visible: false },
        order_date:             { name: I18n.t("#{node}.order_date"),     visible: true },
        producer:               { name: I18n.t("admin.producer"),         visible: true },
        order_cycle:            { name: I18n.t("admin.order_cycle"),      visible: false },
        hub:                    { name: I18n.t("admin.shop"),             visible: false },
        variant:                { name: I18n.t("#{node}.product_unit"),   visible: true },
        quantity:               { name: I18n.t("admin.quantity"),         visible: true },
        max:                    { name: I18n.t("#{node}.max"),            visible: true },
        final_weight_volume:    { name: I18n.t("#{node}.weight_volume"),  visible: false },
        price:                  { name: I18n.t("admin.price"),            visible: false }
      }
    end

    def products_bulk_edit_columns
      node = "spree.admin.products.bulk_edit.products_head"
      {
        producer:             { name: I18n.t("admin.producer"),                visible: true },
        sku:                  { name: I18n.t("admin.sku"),                     visible: false },
        name:                 { name: I18n.t("admin.name"),                    visible: true },
        unit:                 { name: I18n.t("#{node}.unit"),                  visible: true },
        price:                { name: I18n.t("admin.price"),                   visible: true },
        on_hand:              { name: I18n.t("admin.on_hand"),                 visible: true },
        on_demand:            { name: I18n.t("admin.on_demand"),               visible: true },
        category:             { name: I18n.t("#{node}.category"),              visible: false },
        tax_category:         { name: I18n.t("#{node}.tax_category"),          visible: false },
        inherits_properties:  { name: I18n.t("#{node}.inherits_properties?"),  visible: false },
        available_on:         { name: I18n.t("#{node}.available_on"),          visible: false }
      }
    end

    def enterprises_index_columns
      node = "admin.enterprises.index"
      {
        name:     { name: I18n.t("admin.name"),         visible: true },
        producer: { name: I18n.t("#{node}.producer?"),  visible: true },
        package:  { name: I18n.t("#{node}.package"),    visible: true },
        status:   { name: I18n.t("#{node}.status"),     visible: true },
        manage:   { name: I18n.t("#{node}.manage"),     visible: true }
      }
    end

    def order_cycles_index_columns
      node = "admin.order_cycles.index"
      {
        name:         { name: I18n.t("admin.name"),         visible: true },
        schedules:    { name: I18n.t("#{node}.schedules"),  visible: false },
        open:         { name: I18n.t("open"),               visible: true },
        close:        { name: I18n.t("close"),              visible: true },
        producers:    { name: I18n.t("label_producers"),    visible: false },
        coordinator:  { name: I18n.t("coordinator"),        visible: true },
        shops:        { name: I18n.t("label_shops"),        visible: false },
        products:     { name: I18n.t("products"),           visible: true }
      }
    end
  end
end
