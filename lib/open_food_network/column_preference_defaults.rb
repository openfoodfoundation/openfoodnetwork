module OpenFoodNetwork
  module ColumnPreferenceDefaults

    private

    # NOTE: These methods define valid column names (via hash keys)
    # as well as default values for column attributes (eg. visiblity)
    # Default values can be overridden by storing a different value
    # for a given user, action_name and column_name

    def variant_overrides_index_columns
      {
        producer:     { name: "Producer",           visible: true },
        product:      { name: "Product",            visible: true },
        sku:          { name: "SKU",                visible: false },
        price:        { name: "Price",              visible: true },
        on_hand:      { name: "On Hand",            visible: true },
        on_demand:    { name: "On Demand",          visible: false },
        reset:        { name: "Reset Stock Level",  visible: false },
        inheritance:  { name: "Inheritance",        visible: false },
        visibility:   { name: "Hide",               visible: false }
      }
    end

    def customers_index_columns
      {
        email:  { name: "Email", visible: true },
        code:   { name: "Code",  visible: true },
        tags:   { name: "Tags",  visible: true }
      }
    end

    def orders_bulk_management_columns
      {
        order_no:               { name: t("bom_no"),                  visible: false },
        full_name:              { name: t("name"),                    visible: true },
        email:                  { name: t("email"),                   visible: false },
        phone:                  { name: t("phone"),                   visible: false },
        order_date:             { name: t("bom_date"),                visible: true },
        producer:               { name: t("producer"),                visible: true },
        order_cycle:            { name: t("bom_cycle"),               visible: false },
        hub:                    { name: t("bom_hub"),                 visible: false },
        variant:                { name: t("bom_variant"),             visible: true },
        quantity:               { name: t("bom_quantity"),            visible: true },
        max:                    { name: t("bom_max"),                 visible: true },
        final_weight_volume:    { name: t("bom_final_weigth_volume"), visible: false },
        price:                  { name: t("price"),                   visible: false }
      }
    end

    def products_bulk_edit_columns
      {
        producer:             { name: t("products_producer"),             visible: true },
        sku:                  { name: t("products_sku"),                  visible: false },
        name:                 { name: t("products_name"),                 visible: true },
        unit:                 { name: t("products_unit"),                 visible: true },
        price:                { name: t("products_price"),                visible: true },
        on_hand:              { name: t("products_on_hand"),              visible: true },
        on_demand:            { name: t("products_on_demand"),            visible: false },
        category:             { name: t("products_category"),             visible: false },
        tax_category:         { name: t("products_tax_category"),         visible: false },
        inherits_properties:  { name: t("products_inherits_properties"),  visible: false },
        available_on:         { name: t("products_available_on"),         visible: false }
      }
    end

    def enterprises_index_columns
      {
        name:     { name: "Name",     visible: true },
        producer: { name: "Producer", visible: true },
        package:  { name: "Package",  visible: true },
        status:   { name: "Status",   visible: true },
        manage:   { name: "Manage",   visible: true }
      }
    end
  end
end
