# frozen_string_literal: true

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
        producer: { name: I18n.t("admin.producer"), visible: true },
        product: { name: I18n.t("admin.product"), visible: true },
        sku: { name: I18n.t("admin.sku"), visible: false },
        price: { name: I18n.t("admin.price"), visible: true },
        on_hand: { name: I18n.t("admin.on_hand"), visible: true },
        on_demand: { name: I18n.t("admin.on_demand?"), visible: true },
        reset: { name: I18n.t("#{node}.enable_reset?"), visible: false },
        inheritance: { name: I18n.t("#{node}.inherit?"), visible: false },
        tags: { name: I18n.t("admin.tags"), visible: false },
        visibility: { name: I18n.t("#{node}.hide"),           visible: false },
        import_date: { name: I18n.t("#{node}.import_date"),   visible: false }
      }
    end

    def customers_index_columns
      node = 'admin.customers.index'
      {
        email: { name: I18n.t("admin.email"), visible: true },
        first_name: { name: I18n.t("admin.first_name"), visible: true },
        last_name: { name: I18n.t("admin.last_name"), visible: true },
        code: { name: I18n.t("#{node}.code"), visible: true },
        tags: { name: I18n.t("admin.tags"), visible: true },
        bill_address: { name: I18n.t("#{node}.bill_address"), visible: true },
        ship_address: { name: I18n.t("#{node}.ship_address"), visible: true },
        balance: { name: I18n.t("#{node}.balance"), visible: true }
      }
    end

    def orders_bulk_management_columns
      node = "admin.orders.bulk_management"
      {
        order_no: { name: I18n.t("#{node}.order_no"), visible: false },
        full_name: { name: I18n.t("admin.name"), visible: true },
        email: { name: I18n.t("admin.email"),            visible: false },
        phone: { name: I18n.t("admin.phone"),            visible: false },
        order_date: { name: I18n.t("#{node}.order_date"), visible: true },
        producer: { name: I18n.t("admin.producer"), visible: true },
        order_cycle: { name: I18n.t("admin.order_cycle"), visible: false },
        hub: { name: I18n.t("admin.shop"), visible: false },
        variant: { name: I18n.t("#{node}.product_unit"), visible: true },
        quantity: { name: I18n.t("admin.quantity"), visible: true },
        max: { name: I18n.t("#{node}.max"), visible: true },
        final_weight_volume: { name: I18n.t("#{node}.weight_volume"), visible: false },
        price: { name: I18n.t("admin.price"), visible: false }
      }
    end

    def products_index_columns
      node = "spree.admin.products.index.products_head"
      {
        image: { name: I18n.t("admin.image"), visible: true },
        producer: { name: I18n.t("admin.producer"), visible: true },
        name: { name: I18n.t("admin.name"), visible: true },
        unit: { name: I18n.t("#{node}.unit"), visible: true },
        price: { name: I18n.t("admin.price"), visible: true },
        on_hand: { name: I18n.t("admin.on_hand"), visible: true },
        on_demand: { name: I18n.t("admin.on_demand"), visible: true },
        category: { name: I18n.t("#{node}.category"), visible: false },
        tax_category: { name: I18n.t("#{node}.tax_category"), visible: false },
        inherits_properties: { name: I18n.t("#{node}.inherits_properties?"), visible: false },
        import_date: { name: I18n.t("#{node}.import_date"), visible: false }
      }
    end

    def products_v3_index_columns
      I18n.with_options scope: 'admin.products_page.columns' do
        {
          image: { name: t(:image), visible: true },
          name: { name: t(:name), visible: true },
          unit: { name: t(:unit), visible: true },
          unit_scale: { name: t(:unit_scale), visible: true },
          price: { name: t(:price), visible: true },
          on_hand: { name: t(:on_hand), visible: true },
          producer: { name: t(:producer), visible: true },
          category: { name: t(:category), visible: true },
          tax_category: { name: t(:tax_category), visible: true },
          inherits_properties: { name: t(:inherits_properties), visible: true },
        }
      end
    end

    def enterprises_index_columns
      node = "admin.enterprises.index"
      {
        name: { name: I18n.t("admin.name"), visible: true },
        producer: { name: I18n.t("#{node}.producer?"), visible: true },
        package: { name: I18n.t("#{node}.package"), visible: true },
        status: { name: I18n.t("#{node}.status"),     visible: true },
        manage: { name: I18n.t("#{node}.manage"),     visible: true }
      }
    end

    def order_cycles_index_columns
      node = "admin.order_cycles.index"
      {
        name: { name: I18n.t("admin.name"), visible: true },
        schedules: { name: I18n.t("#{node}.schedules"), visible: true },
        open: { name: I18n.t("open"), visible: true },
        close: { name: I18n.t("close"), visible: true },
        producers: { name: I18n.t("label_producers"), visible: false },
        coordinator: { name: I18n.t("coordinator"), visible: true },
        shops: { name: I18n.t("label_shops"), visible: false },
        products: { name: I18n.t("products"), visible: true }
      }
    end

    def subscriptions_index_columns
      _node = "admin.subscriptions.index"
      {
        customer: { name: I18n.t("admin.customer"),         visible: true },
        schedule: { name: I18n.t("admin.schedule"),         visible: true },
        items: { name: I18n.t("items"), visible: true },
        orders: { name: I18n.t("orders"), visible: true },
        state: { name: I18n.t("admin.status_state"), visible: true },
        begins_on: { name: I18n.t("admin.begins_on"), visible: false },
        ends_on: { name: I18n.t("admin.ends_on"), visible: false },
        payment_method: { name: I18n.t("admin.payment_method"), visible: false },
        shipping_method: { name: I18n.t("admin.shipping_method"), visible: false }
      }
    end
  end
end
