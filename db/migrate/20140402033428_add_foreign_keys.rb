class AddForeignKeys < ActiveRecord::Migration
  class AdjustmentMetadata < ActiveRecord::Base; end
  class CoordinatorFee < ActiveRecord::Base; end
  class Enterprise < ActiveRecord::Base
    belongs_to :address, :class_name => 'Spree::Address'
  end
  class ExchangeVariant < ActiveRecord::Base; end
  class Spree::InventoryUnit < ActiveRecord::Base; end
  class Spree::LineItem < ActiveRecord::Base; end
  class Spree::Address < ActiveRecord::Base; end
  class Spree::Order < ActiveRecord::Base; end
  class Spree::Taxon < ActiveRecord::Base; end

  def change
    setup_foreign_keys
  end

  # http://stackoverflow.com/a/7679513/2720566
  def migrate(direction)
    sanitise_data if direction == :up
    super
  end


  private

  def sanitise_data
    # Remove orphaned AdjustmentMetadata records
    orphaned_adjustment_metadata = AdjustmentMetadata.joins('LEFT OUTER JOIN spree_adjustments ON spree_adjustments.id = adjustment_metadata.adjustment_id').where('spree_adjustments.id IS NULL')
    say "Destroying #{orphaned_adjustment_metadata.count} orphaned AdjustmentMetadata (of total #{AdjustmentMetadata.count})"
    orphaned_adjustment_metadata.destroy_all

    # Remove orphaned ExchangeVariants
    orphaned_exchange_variants = ExchangeVariant.joins('LEFT OUTER JOIN spree_variants ON spree_variants.id=exchange_variants.variant_id').where('spree_variants.id IS NULL')
    say "Destroying #{orphaned_exchange_variants.count} orphaned ExchangeVariants (of total #{ExchangeVariant.count})"
    orphaned_exchange_variants.destroy_all

    # Remove orphaned ExchangeFee records
    orphaned_exchange_fees = ExchangeFee.joins('LEFT OUTER JOIN enterprise_fees ON enterprise_fees.id=exchange_fees.enterprise_fee_id').where('enterprise_fees.id IS NULL')
    say "Destroying #{orphaned_exchange_fees.count} orphaned ExchangeFees (of total #{ExchangeFee.count})"
    orphaned_exchange_fees.destroy_all

    # Remove orphaned Spree::InventoryUnits
    orphaned_inventory_units = Spree::InventoryUnit.joins('LEFT OUTER JOIN spree_variants ON spree_variants.id=spree_inventory_units.variant_id').where('spree_variants.id IS NULL')
    say "Destroying #{orphaned_inventory_units.count} orphaned InventoryUnits (of total #{Spree::InventoryUnit.count})"
    orphaned_inventory_units.destroy_all
    
    # Remove orphaned Spree::LineItems
    orphaned_line_items = Spree::LineItem.
      joins('LEFT OUTER JOIN spree_variants ON spree_variants.id=spree_line_items.variant_id').
      joins('LEFT OUTER JOIN spree_orders ON spree_orders.id=spree_line_items.order_id').
      where('spree_variants.id IS NULL OR spree_orders.id IS NULL')
    say "Destroying #{orphaned_line_items.count} orphaned LineItems (of total #{Spree::LineItem.count})"
    orphaned_line_items.each { |li| li.delete }

    # Update orders without a distributor with a dummy distributor
    state = Spree::State.first
    country = state.andand.country
    unless country && state
      country = Spree::Country.create! name: 'Australia', iso_name: 'AU'
      state = country.states.create! name: 'Victoria'
    end

    address = Spree::Address.create!(firstname: 'Dummy distributor', lastname: 'Dummy distributor', phone: '12345678', state: state,
                                     address1: 'Dummy distributor', city: 'Dummy distributor', zipcode: '1234', country: country)
    Enterprise.reset_column_information
    deleted_distributor = Enterprise.create!(name: "Deleted distributor", address: address)

    orphaned_orders = Spree::Order.joins('LEFT OUTER JOIN enterprises ON enterprises.id=spree_orders.distributor_id').where('enterprises.id IS NULL')
    say "Assigning a dummy distributor to #{orphaned_orders.count} orders with a deleted distributor (of total #{Spree::Order.count})"
    orphaned_orders.update_all distributor_id: deleted_distributor.id

    # Remove orphaned Spree::Taxons
    orphaned_taxons = Spree::Taxon.joins('LEFT OUTER JOIN spree_taxonomies ON spree_taxonomies.id=spree_taxons.taxonomy_id').where('spree_taxonomies.id IS NULL')
    say "Destroying #{orphaned_taxons.count} orphaned Taxons (of total #{Spree::Taxon.count})"
    orphaned_taxons.destroy_all

    # Remove orphaned CoordinatorFee records
    orphaned_coordinator_fees = CoordinatorFee.joins('LEFT OUTER JOIN enterprise_fees ON enterprise_fees.id = coordinator_fees.enterprise_fee_id').where('enterprise_fees.id IS NULL')
    say "Destroying #{orphaned_coordinator_fees.count} orphaned CoordinatorFees (of total #{CoordinatorFee.count})"
    orphaned_coordinator_fees.each do |cf|
      CoordinatorFee.connection.execute("DELETE FROM coordinator_fees WHERE coordinator_fees.order_cycle_id=#{cf.order_cycle_id} AND coordinator_fees.enterprise_fee_id=#{cf.enterprise_fee_id}")
    end
  end


  def setup_foreign_keys
    add_foreign_key "adjustment_metadata", "spree_adjustments", name: "adjustment_metadata_adjustment_id_fk", column: "adjustment_id"
    add_foreign_key "adjustment_metadata", "enterprises", name: "adjustment_metadata_enterprise_id_fk"
    add_foreign_key "carts", "spree_users", name: "carts_user_id_fk", column: "user_id"
    add_foreign_key "cms_blocks", "cms_pages", name: "cms_blocks_page_id_fk", column: "page_id"
    add_foreign_key "cms_categories", "cms_sites", name: "cms_categories_site_id_fk", column: "site_id", dependent: :delete
    add_foreign_key "cms_categorizations", "cms_categories", name: "cms_categorizations_category_id_fk", column: "category_id"
    add_foreign_key "cms_files", "cms_blocks", name: "cms_files_block_id_fk", column: "block_id"
    add_foreign_key "cms_files", "cms_sites", name: "cms_files_site_id_fk", column: "site_id"
    add_foreign_key "cms_layouts", "cms_layouts", name: "cms_layouts_parent_id_fk", column: "parent_id"
    add_foreign_key "cms_layouts", "cms_sites", name: "cms_layouts_site_id_fk", column: "site_id", dependent: :delete
    add_foreign_key "cms_pages", "cms_layouts", name: "cms_pages_layout_id_fk", column: "layout_id"
    add_foreign_key "cms_pages", "cms_pages", name: "cms_pages_parent_id_fk", column: "parent_id"
    add_foreign_key "cms_pages", "cms_sites", name: "cms_pages_site_id_fk", column: "site_id", dependent: :delete
    add_foreign_key "cms_pages", "cms_pages", name: "cms_pages_target_page_id_fk", column: "target_page_id"
    add_foreign_key "cms_snippets", "cms_sites", name: "cms_snippets_site_id_fk", column: "site_id", dependent: :delete
    add_foreign_key "coordinator_fees", "enterprise_fees", name: "coordinator_fees_enterprise_fee_id_fk"
    add_foreign_key "coordinator_fees", "order_cycles", name: "coordinator_fees_order_cycle_id_fk"
    add_foreign_key "distributors_payment_methods", "enterprises", name: "distributors_payment_methods_distributor_id_fk", column: "distributor_id"
    add_foreign_key "distributors_payment_methods", "spree_payment_methods", name: "distributors_payment_methods_payment_method_id_fk", column: "payment_method_id"
    add_foreign_key "distributors_shipping_methods", "enterprises", name: "distributors_shipping_methods_distributor_id_fk", column: "distributor_id"
    add_foreign_key "distributors_shipping_methods", "spree_shipping_methods", name: "distributors_shipping_methods_shipping_method_id_fk", column: "shipping_method_id"
    add_foreign_key "enterprise_fees", "enterprises", name: "enterprise_fees_enterprise_id_fk"
    add_foreign_key "enterprise_groups_enterprises", "enterprise_groups", name: "enterprise_groups_enterprises_enterprise_group_id_fk"
    add_foreign_key "enterprise_groups_enterprises", "enterprises", name: "enterprise_groups_enterprises_enterprise_id_fk"
    add_foreign_key "enterprise_roles", "enterprises", name: "enterprise_roles_enterprise_id_fk"
    add_foreign_key "enterprise_roles", "spree_users", name: "enterprise_roles_user_id_fk", column: "user_id"
    add_foreign_key "enterprises", "spree_addresses", name: "enterprises_address_id_fk", column: "address_id"
    add_foreign_key "exchange_fees", "enterprise_fees", name: "exchange_fees_enterprise_fee_id_fk"
    add_foreign_key "exchange_fees", "exchanges", name: "exchange_fees_exchange_id_fk"
    add_foreign_key "exchange_variants", "exchanges", name: "exchange_variants_exchange_id_fk"
    add_foreign_key "exchange_variants", "spree_variants", name: "exchange_variants_variant_id_fk", column: "variant_id"
    add_foreign_key "exchanges", "order_cycles", name: "exchanges_order_cycle_id_fk"
    add_foreign_key "exchanges", "enterprises", name: "exchanges_payment_enterprise_id_fk", column: "payment_enterprise_id"
    add_foreign_key "exchanges", "enterprises", name: "exchanges_receiver_id_fk", column: "receiver_id"
    add_foreign_key "exchanges", "enterprises", name: "exchanges_sender_id_fk", column: "sender_id"
    add_foreign_key "order_cycles", "enterprises", name: "order_cycles_coordinator_id_fk", column: "coordinator_id"
    add_foreign_key "product_distributions", "enterprises", name: "product_distributions_distributor_id_fk", column: "distributor_id"
    add_foreign_key "product_distributions", "enterprise_fees", name: "product_distributions_enterprise_fee_id_fk"
    add_foreign_key "product_distributions", "spree_products", name: "product_distributions_product_id_fk", column: "product_id"
    add_foreign_key "spree_addresses", "spree_countries", name: "spree_addresses_country_id_fk", column: "country_id"
    add_foreign_key "spree_addresses", "spree_states", name: "spree_addresses_state_id_fk", column: "state_id"
    add_foreign_key "spree_inventory_units", "spree_orders", name: "spree_inventory_units_order_id_fk", column: "order_id"
    add_foreign_key "spree_inventory_units", "spree_return_authorizations", name: "spree_inventory_units_return_authorization_id_fk", column: "return_authorization_id"
    add_foreign_key "spree_inventory_units", "spree_shipments", name: "spree_inventory_units_shipment_id_fk", column: "shipment_id"
    add_foreign_key "spree_inventory_units", "spree_variants", name: "spree_inventory_units_variant_id_fk", column: "variant_id"
    add_foreign_key "spree_line_items", "spree_orders", name: "spree_line_items_order_id_fk", column: "order_id"
    add_foreign_key "spree_line_items", "spree_variants", name: "spree_line_items_variant_id_fk", column: "variant_id"
    add_foreign_key "spree_option_types_prototypes", "spree_option_types", name: "spree_option_types_prototypes_option_type_id_fk", column: "option_type_id"
    add_foreign_key "spree_option_types_prototypes", "spree_prototypes", name: "spree_option_types_prototypes_prototype_id_fk", column: "prototype_id"
    add_foreign_key "spree_option_values", "spree_option_types", name: "spree_option_values_option_type_id_fk", column: "option_type_id"
    add_foreign_key "spree_option_values_variants", "spree_option_values", name: "spree_option_values_variants_option_value_id_fk", column: "option_value_id"
    add_foreign_key "spree_option_values_variants", "spree_variants", name: "spree_option_values_variants_variant_id_fk", column: "variant_id"
    add_foreign_key "spree_orders", "spree_addresses", name: "spree_orders_bill_address_id_fk", column: "bill_address_id"
    add_foreign_key "spree_orders", "carts", name: "spree_orders_cart_id_fk"
    add_foreign_key "spree_orders", "enterprises", name: "spree_orders_distributor_id_fk", column: "distributor_id"
    add_foreign_key "spree_orders", "order_cycles", name: "spree_orders_order_cycle_id_fk"
    add_foreign_key "spree_orders", "spree_addresses", name: "spree_orders_ship_address_id_fk", column: "ship_address_id"
    #add_foreign_key "spree_orders", "spree_shipping_methods", name: "spree_orders_shipping_method_id_fk", column: "shipping_method_id"
    add_foreign_key "spree_orders", "spree_users", name: "spree_orders_user_id_fk", column: "user_id"
    add_foreign_key "spree_payments", "spree_orders", name: "spree_payments_order_id_fk", column: "order_id"
    add_foreign_key "spree_payments", "spree_payment_methods", name: "spree_payments_payment_method_id_fk", column: "payment_method_id"
    #add_foreign_key "spree_payments", "spree_payments", name: "spree_payments_source_id_fk", column: "source_id"
    add_foreign_key "spree_prices", "spree_variants", name: "spree_prices_variant_id_fk", column: "variant_id"
    add_foreign_key "spree_product_option_types", "spree_option_types", name: "spree_product_option_types_option_type_id_fk", column: "option_type_id"
    add_foreign_key "spree_product_option_types", "spree_products", name: "spree_product_option_types_product_id_fk", column: "product_id"
    add_foreign_key "spree_product_properties", "spree_products", name: "spree_product_properties_product_id_fk", column: "product_id"
    add_foreign_key "spree_product_properties", "spree_properties", name: "spree_product_properties_property_id_fk", column: "property_id"
    add_foreign_key "spree_products_promotion_rules", "spree_products", name: "spree_products_promotion_rules_product_id_fk", column: "product_id"
    add_foreign_key "spree_products_promotion_rules", "spree_promotion_rules", name: "spree_products_promotion_rules_promotion_rule_id_fk", column: "promotion_rule_id"
    add_foreign_key "spree_products", "spree_shipping_categories", name: "spree_products_shipping_category_id_fk", column: "shipping_category_id"
    add_foreign_key "spree_products", "enterprises", name: "spree_products_supplier_id_fk", column: "supplier_id"
    add_foreign_key "spree_products", "spree_tax_categories", name: "spree_products_tax_category_id_fk", column: "tax_category_id"
    add_foreign_key "spree_products_taxons", "spree_products", name: "spree_products_taxons_product_id_fk", column: "product_id", dependent: :delete
    add_foreign_key "spree_products_taxons", "spree_taxons", name: "spree_products_taxons_taxon_id_fk", column: "taxon_id", dependent: :delete
    add_foreign_key "spree_promotion_action_line_items", "spree_promotion_actions", name: "spree_promotion_action_line_items_promotion_action_id_fk", column: "promotion_action_id"
    add_foreign_key "spree_promotion_action_line_items", "spree_variants", name: "spree_promotion_action_line_items_variant_id_fk", column: "variant_id"
    add_foreign_key "spree_promotion_actions", "spree_activators", name: "spree_promotion_actions_activator_id_fk", column: "activator_id"
    add_foreign_key "spree_promotion_rules", "spree_activators", name: "spree_promotion_rules_activator_id_fk", column: "activator_id"
    add_foreign_key "spree_properties_prototypes", "spree_properties", name: "spree_properties_prototypes_property_id_fk", column: "property_id"
    add_foreign_key "spree_properties_prototypes", "spree_prototypes", name: "spree_properties_prototypes_prototype_id_fk", column: "prototype_id"
    add_foreign_key "spree_return_authorizations", "spree_orders", name: "spree_return_authorizations_order_id_fk", column: "order_id"
    add_foreign_key "spree_roles_users", "spree_roles", name: "spree_roles_users_role_id_fk", column: "role_id"
    add_foreign_key "spree_roles_users", "spree_users", name: "spree_roles_users_user_id_fk", column: "user_id"
    add_foreign_key "spree_shipments", "spree_addresses", name: "spree_shipments_address_id_fk", column: "address_id"
    add_foreign_key "spree_shipments", "spree_orders", name: "spree_shipments_order_id_fk", column: "order_id"
    #add_foreign_key "spree_shipments", "spree_shipping_methods", name: "spree_shipments_shipping_method_id_fk", column: "shipping_method_id"
    add_foreign_key "spree_shipping_methods", "spree_shipping_categories", name: "spree_shipping_methods_shipping_category_id_fk", column: "shipping_category_id"
    add_foreign_key "spree_shipping_methods", "spree_zones", name: "spree_shipping_methods_zone_id_fk", column: "zone_id"
    add_foreign_key "spree_state_changes", "spree_users", name: "spree_state_changes_user_id_fk", column: "user_id"
    add_foreign_key "spree_states", "spree_countries", name: "spree_states_country_id_fk", column: "country_id"
    add_foreign_key "spree_tax_rates", "spree_tax_categories", name: "spree_tax_rates_tax_category_id_fk", column: "tax_category_id"
    add_foreign_key "spree_tax_rates", "spree_zones", name: "spree_tax_rates_zone_id_fk", column: "zone_id"
    add_foreign_key "spree_taxons", "spree_taxons", name: "spree_taxons_parent_id_fk", column: "parent_id"
    add_foreign_key "spree_taxons", "spree_taxonomies", name: "spree_taxons_taxonomy_id_fk", column: "taxonomy_id"
    add_foreign_key "spree_users", "spree_addresses", name: "spree_users_bill_address_id_fk", column: "bill_address_id"
    add_foreign_key "spree_users", "spree_addresses", name: "spree_users_ship_address_id_fk", column: "ship_address_id"
    add_foreign_key "spree_variants", "spree_products", name: "spree_variants_product_id_fk", column: "product_id"
    add_foreign_key "spree_zone_members", "spree_zones", name: "spree_zone_members_zone_id_fk", column: "zone_id"
    add_foreign_key "suburbs", "spree_states", name: "suburbs_state_id_fk", column: "state_id"
  end
end
