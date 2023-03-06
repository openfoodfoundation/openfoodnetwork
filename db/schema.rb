# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_02_13_160135) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "adjustment_metadata", id: :serial, force: :cascade do |t|
    t.integer "adjustment_id"
    t.integer "enterprise_id"
    t.string "fee_name", limit: 255
    t.string "fee_type", limit: 255
    t.string "enterprise_role", limit: 255
    t.index ["adjustment_id"], name: "index_adjustment_metadata_on_adjustment_id"
    t.index ["enterprise_id"], name: "index_adjustment_metadata_on_enterprise_id"
  end

  create_table "column_preferences", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "action_name", limit: 255, null: false
    t.string "column_name", limit: 255, null: false
    t.boolean "visible", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "action_name", "column_name"], name: "index_column_prefs_on_user_id_and_action_name_and_column_name", unique: true
  end

  create_table "coordinator_fees", id: :serial, force: :cascade do |t|
    t.integer "order_cycle_id"
    t.integer "enterprise_fee_id"
    t.index ["enterprise_fee_id"], name: "index_coordinator_fees_on_enterprise_fee_id"
    t.index ["order_cycle_id"], name: "index_coordinator_fees_on_order_cycle_id"
  end

  create_table "customers", id: :serial, force: :cascade do |t|
    t.string "email", limit: 255, null: false
    t.integer "enterprise_id", null: false
    t.string "code", limit: 255
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bill_address_id"
    t.integer "ship_address_id"
    t.string "name", limit: 255
    t.boolean "allow_charges", default: false, null: false
    t.datetime "terms_and_conditions_accepted_at"
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.index ["bill_address_id"], name: "index_customers_on_bill_address_id"
    t.index ["email"], name: "index_customers_on_email"
    t.index ["enterprise_id", "code"], name: "index_customers_on_enterprise_id_and_code", unique: true
    t.index ["ship_address_id"], name: "index_customers_on_ship_address_id"
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by", limit: 255
    t.string "queue", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "distributors_payment_methods", force: :cascade do |t|
    t.integer "distributor_id"
    t.integer "payment_method_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["distributor_id"], name: "index_distributors_payment_methods_on_distributor_id"
    t.index ["payment_method_id"], name: "index_distributors_payment_methods_on_payment_method_id"
  end

  create_table "distributors_shipping_methods", id: :serial, force: :cascade do |t|
    t.integer "distributor_id"
    t.integer "shipping_method_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["distributor_id"], name: "index_distributors_shipping_methods_on_distributor_id"
    t.index ["shipping_method_id"], name: "index_distributors_shipping_methods_on_shipping_method_id"
  end

  create_table "enterprise_fees", id: :serial, force: :cascade do |t|
    t.integer "enterprise_id"
    t.string "fee_type", limit: 255
    t.string "name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tax_category_id"
    t.boolean "inherits_tax_category", default: false, null: false
    t.datetime "deleted_at"
    t.index ["enterprise_id"], name: "index_enterprise_fees_on_enterprise_id"
    t.index ["tax_category_id"], name: "index_enterprise_fees_on_tax_category_id"
  end

  create_table "enterprise_groups", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.boolean "on_front_page"
    t.integer "position"
    t.text "description"
    t.text "long_description"
    t.integer "address_id"
    t.string "email", limit: 255, default: "", null: false
    t.string "website", limit: 255, default: "", null: false
    t.string "facebook", limit: 255, default: "", null: false
    t.string "instagram", limit: 255, default: "", null: false
    t.string "linkedin", limit: 255, default: "", null: false
    t.string "twitter", limit: 255, default: "", null: false
    t.integer "owner_id"
    t.string "permalink", limit: 255, null: false
    t.index ["address_id"], name: "index_enterprise_groups_on_address_id"
    t.index ["owner_id"], name: "index_enterprise_groups_on_owner_id"
    t.index ["permalink"], name: "index_enterprise_groups_on_permalink", unique: true
  end

  create_table "enterprise_groups_enterprises", id: false, force: :cascade do |t|
    t.integer "enterprise_group_id"
    t.integer "enterprise_id"
    t.index ["enterprise_group_id"], name: "index_enterprise_groups_enterprises_on_enterprise_group_id"
    t.index ["enterprise_id"], name: "index_enterprise_groups_enterprises_on_enterprise_id"
  end

  create_table "enterprise_relationship_permissions", id: :serial, force: :cascade do |t|
    t.integer "enterprise_relationship_id"
    t.string "name", limit: 255, null: false
    t.index ["enterprise_relationship_id"], name: "index_erp_on_erid"
  end

  create_table "enterprise_relationships", id: :serial, force: :cascade do |t|
    t.integer "parent_id"
    t.integer "child_id"
    t.index ["child_id"], name: "index_enterprise_relationships_on_child_id"
    t.index ["parent_id", "child_id"], name: "index_enterprise_relationships_on_parent_id_and_child_id", unique: true
    t.index ["parent_id"], name: "index_enterprise_relationships_on_parent_id"
  end

  create_table "enterprise_roles", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "enterprise_id"
    t.boolean "receives_notifications", default: false
    t.index ["enterprise_id", "user_id"], name: "index_enterprise_roles_on_enterprise_id_and_user_id", unique: true
    t.index ["enterprise_id"], name: "index_enterprise_roles_on_enterprise_id"
    t.index ["user_id", "enterprise_id"], name: "index_enterprise_roles_on_user_id_and_enterprise_id", unique: true
    t.index ["user_id"], name: "index_enterprise_roles_on_user_id"
  end

  create_table "enterprises", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.text "description"
    t.text "long_description"
    t.boolean "is_primary_producer"
    t.string "contact_name", limit: 255
    t.string "phone", limit: 255
    t.string "website", limit: 255
    t.string "twitter", limit: 255
    t.string "abn", limit: 255
    t.string "acn", limit: 255
    t.integer "address_id"
    t.text "pickup_times"
    t.string "next_collection_at", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "distributor_info"
    t.string "facebook", limit: 255
    t.string "instagram", limit: 255
    t.string "linkedin", limit: 255
    t.integer "owner_id", null: false
    t.string "sells", limit: 255, default: "none", null: false
    t.boolean "producer_profile_only", default: false
    t.string "permalink", limit: 255, null: false
    t.boolean "charges_sales_tax", default: false, null: false
    t.string "email_address", limit: 255
    t.boolean "require_login", default: false, null: false
    t.boolean "allow_guest_orders", default: true, null: false
    t.text "invoice_text"
    t.boolean "display_invoice_logo", default: false
    t.boolean "allow_order_changes", default: false, null: false
    t.boolean "enable_subscriptions", default: false, null: false
    t.integer "business_address_id"
    t.boolean "show_customer_names_to_suppliers", default: false, null: false
    t.string "visible", limit: 255, default: "public", null: false
    t.string "whatsapp_phone", limit: 255
    t.index ["address_id"], name: "index_enterprises_on_address_id"
    t.index ["is_primary_producer", "sells"], name: "index_enterprises_on_is_primary_producer_and_sells"
    t.index ["name"], name: "index_enterprises_on_name", unique: true
    t.index ["owner_id"], name: "index_enterprises_on_owner_id"
    t.index ["permalink"], name: "index_enterprises_on_permalink", unique: true
    t.index ["sells"], name: "index_enterprises_on_sells"
  end

  create_table "exchange_fees", id: :serial, force: :cascade do |t|
    t.integer "exchange_id"
    t.integer "enterprise_fee_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enterprise_fee_id"], name: "index_exchange_fees_on_enterprise_fee_id"
    t.index ["exchange_id"], name: "index_exchange_fees_on_exchange_id"
  end

  create_table "exchange_variants", id: :serial, force: :cascade do |t|
    t.integer "exchange_id"
    t.integer "variant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exchange_id"], name: "index_exchange_variants_on_exchange_id"
    t.index ["variant_id"], name: "index_exchange_variants_on_variant_id"
  end

  create_table "exchanges", id: :serial, force: :cascade do |t|
    t.integer "order_cycle_id"
    t.integer "sender_id"
    t.integer "receiver_id"
    t.text "pickup_time"
    t.text "pickup_instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "incoming", default: false, null: false
    t.text "receival_instructions"
    t.index ["order_cycle_id"], name: "index_exchanges_on_order_cycle_id"
    t.index ["receiver_id"], name: "index_exchanges_on_receiver_id"
    t.index ["sender_id"], name: "index_exchanges_on_sender_id"
  end

  create_table "flipper_features", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", id: :serial, force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "inventory_items", id: :serial, force: :cascade do |t|
    t.integer "enterprise_id", null: false
    t.integer "variant_id", null: false
    t.boolean "visible", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enterprise_id", "variant_id"], name: "index_inventory_items_on_enterprise_id_and_variant_id", unique: true
  end

  create_table "order_cycle_schedules", id: :serial, force: :cascade do |t|
    t.integer "order_cycle_id", null: false
    t.integer "schedule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_cycle_id"], name: "index_order_cycle_schedules_on_order_cycle_id"
    t.index ["schedule_id"], name: "index_order_cycle_schedules_on_schedule_id"
  end

  create_table "order_cycles", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "orders_open_at"
    t.datetime "orders_close_at"
    t.integer "coordinator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "processed_at"
    t.boolean "automatic_notifications", default: false
    t.boolean "mails_sent", default: false
  end

  create_table "order_cycles_distributor_payment_methods", id: false, force: :cascade do |t|
    t.bigint "order_cycle_id"
    t.bigint "distributor_payment_method_id"
    t.index ["distributor_payment_method_id"], name: "index_dpm_id_on_order_cycles_distributor_payment_methods"
    t.index ["order_cycle_id", "distributor_payment_method_id"], name: "order_cycles_distributor_payment_methods_join_index", unique: true
    t.index ["order_cycle_id"], name: "index_oc_id_on_order_cycles_distributor_payment_methods"
  end

  create_table "order_cycles_distributor_shipping_methods", id: false, force: :cascade do |t|
    t.bigint "order_cycle_id"
    t.bigint "distributor_shipping_method_id"
    t.index ["distributor_shipping_method_id"], name: "index_dsm_id_on_order_cycles_distributor_shipping_methods"
    t.index ["order_cycle_id", "distributor_shipping_method_id"], name: "order_cycles_distributor_shipping_methods_join_index", unique: true
    t.index ["order_cycle_id"], name: "index_oc_id_on_order_cycles_distributor_shipping_methods"
  end

  create_table "producer_properties", id: :serial, force: :cascade do |t|
    t.string "value", limit: 255
    t.integer "producer_id"
    t.integer "property_id"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_producer_properties_on_position"
    t.index ["producer_id"], name: "index_producer_properties_on_producer_id"
    t.index ["property_id"], name: "index_producer_properties_on_property_id"
  end

  create_table "proxy_orders", id: :serial, force: :cascade do |t|
    t.integer "subscription_id", null: false
    t.integer "order_id"
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order_cycle_id", null: false
    t.datetime "placed_at"
    t.datetime "confirmed_at"
    t.index ["order_cycle_id", "subscription_id"], name: "index_proxy_orders_on_order_cycle_id_and_subscription_id", unique: true
    t.index ["order_id"], name: "index_proxy_orders_on_order_id", unique: true
    t.index ["subscription_id"], name: "index_proxy_orders_on_subscription_id"
  end

  create_table "report_rendering_options", force: :cascade do |t|
    t.bigint "user_id"
    t.text "options"
    t.string "report_type"
    t.string "report_subtype"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_report_rendering_options_on_user_id"
  end

  create_table "schedules", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255, null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "spree_activators", id: :serial, force: :cascade do |t|
    t.string "description", limit: 255
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "starts_at"
    t.string "name", limit: 255
    t.string "event_name", limit: 255
    t.string "type", limit: 255
    t.integer "usage_limit"
    t.string "match_policy", limit: 255, default: "all"
    t.string "code", limit: 255
    t.boolean "advertise", default: false
    t.string "path", limit: 255
  end

  create_table "spree_addresses", id: :serial, force: :cascade do |t|
    t.string "firstname", limit: 255
    t.string "lastname", limit: 255
    t.string "address1", limit: 255
    t.string "address2", limit: 255
    t.string "city", limit: 255
    t.string "zipcode", limit: 255
    t.string "phone", limit: 255
    t.string "state_name", limit: 255
    t.string "alternative_phone", limit: 255
    t.integer "state_id"
    t.integer "country_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "company", limit: 255
    t.float "latitude"
    t.float "longitude"
    t.index ["firstname"], name: "index_addresses_on_firstname"
    t.index ["lastname"], name: "index_addresses_on_lastname"
  end

  create_table "spree_adjustments", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.string "label", limit: 255
    t.integer "adjustable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "mandatory"
    t.integer "originator_id"
    t.string "originator_type", limit: 255
    t.boolean "eligible", default: true
    t.string "adjustable_type", limit: 255
    t.decimal "included_tax", precision: 10, scale: 2, default: "0.0", null: false
    t.string "state", limit: 255
    t.integer "order_id"
    t.boolean "included", default: false
    t.integer "tax_category_id"
    t.index ["adjustable_type", "adjustable_id"], name: "index_spree_adjustments_on_adjustable_type_and_adjustable_id"
    t.index ["order_id"], name: "index_spree_adjustments_on_order_id"
    t.index ["originator_type", "originator_id"], name: "index_spree_adjustments_on_originator_type_and_originator_id"
    t.index ["tax_category_id"], name: "index_spree_adjustments_on_tax_category_id"
  end

  create_table "spree_assets", id: :serial, force: :cascade do |t|
    t.integer "viewable_id"
    t.integer "position"
    t.string "viewable_type", limit: 50
    t.string "type", limit: 75
    t.text "alt"
    t.index ["viewable_id"], name: "index_assets_on_viewable_id"
    t.index ["viewable_type", "type"], name: "index_assets_on_viewable_type_and_type"
  end

  create_table "spree_calculators", id: :serial, force: :cascade do |t|
    t.string "type", limit: 255
    t.integer "calculable_id", null: false
    t.string "calculable_type", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_configurations", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "type", limit: 50
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "type"], name: "index_configurations_on_name_and_type"
  end

  create_table "spree_countries", id: :serial, force: :cascade do |t|
    t.string "iso_name", limit: 255
    t.string "iso", limit: 255
    t.string "iso3", limit: 255
    t.string "name", limit: 255
    t.integer "numcode"
    t.boolean "states_required", default: true
  end

  create_table "spree_credit_cards", id: :serial, force: :cascade do |t|
    t.string "month", limit: 255
    t.string "year", limit: 255
    t.string "cc_type", limit: 255
    t.string "last_digits", limit: 255
    t.string "first_name", limit: 255
    t.string "last_name", limit: 255
    t.string "start_month", limit: 255
    t.string "start_year", limit: 255
    t.string "issue_number", limit: 255
    t.integer "address_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "gateway_customer_profile_id", limit: 255
    t.string "gateway_payment_profile_id", limit: 255
    t.integer "user_id"
    t.integer "payment_method_id"
    t.boolean "is_default", default: false
    t.index ["payment_method_id"], name: "index_spree_credit_cards_on_payment_method_id"
    t.index ["user_id"], name: "index_spree_credit_cards_on_user_id"
  end

  create_table "spree_gateways", id: :serial, force: :cascade do |t|
    t.string "type", limit: 255
    t.string "name", limit: 255
    t.text "description"
    t.boolean "active", default: true
    t.string "environment", limit: 255, default: "development"
    t.string "server", limit: 255, default: "test"
    t.boolean "test_mode", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_inventory_units", id: :serial, force: :cascade do |t|
    t.string "state", limit: 255
    t.integer "variant_id"
    t.integer "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "shipment_id"
    t.integer "return_authorization_id"
    t.boolean "pending", default: true
    t.index ["order_id"], name: "index_inventory_units_on_order_id"
    t.index ["shipment_id"], name: "index_inventory_units_on_shipment_id"
    t.index ["variant_id"], name: "index_inventory_units_on_variant_id"
  end

  create_table "spree_line_items", id: :serial, force: :cascade do |t|
    t.integer "order_id"
    t.integer "variant_id"
    t.integer "quantity", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "max_quantity"
    t.string "currency", limit: 255
    t.decimal "distribution_fee", precision: 10, scale: 2
    t.decimal "final_weight_volume", precision: 10, scale: 2
    t.integer "tax_category_id"
    t.decimal "weight", precision: 8, scale: 2
    t.decimal "height", precision: 8, scale: 2
    t.decimal "width", precision: 8, scale: 2
    t.decimal "depth", precision: 8, scale: 2
    t.index ["order_id"], name: "index_line_items_on_order_id"
    t.index ["variant_id"], name: "index_line_items_on_variant_id"
  end

  create_table "spree_log_entries", id: :serial, force: :cascade do |t|
    t.integer "source_id"
    t.string "source_type", limit: 255
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_option_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 100
    t.string "presentation", limit: 100
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0, null: false
  end

  create_table "spree_option_values", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.string "name", limit: 255
    t.string "presentation", limit: 255
    t.integer "option_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_option_values_line_items", id: false, force: :cascade do |t|
    t.integer "line_item_id"
    t.integer "option_value_id"
    t.index ["line_item_id"], name: "index_option_values_line_items_on_line_item_id"
  end

  create_table "spree_option_values_variants", id: false, force: :cascade do |t|
    t.integer "variant_id"
    t.integer "option_value_id"
    t.index ["variant_id", "option_value_id"], name: "index_option_values_variants_on_variant_id_and_option_value_id"
    t.index ["variant_id"], name: "index_option_values_variants_on_variant_id"
  end

  create_table "spree_orders", id: :serial, force: :cascade do |t|
    t.string "number", limit: 15
    t.decimal "item_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.string "state", limit: 255
    t.decimal "adjustment_total", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "completed_at"
    t.integer "bill_address_id"
    t.integer "ship_address_id"
    t.decimal "payment_total", precision: 10, scale: 2, default: "0.0"
    t.string "shipment_state", limit: 255
    t.string "payment_state", limit: 255
    t.string "email", limit: 255
    t.text "special_instructions"
    t.integer "distributor_id"
    t.integer "order_cycle_id"
    t.string "currency", limit: 255
    t.string "last_ip_address", limit: 255
    t.integer "customer_id"
    t.integer "created_by_id"
    t.decimal "included_tax_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "additional_tax_total", precision: 10, scale: 2, default: "0.0", null: false
    t.string "note", default: "", null: false
    t.index ["completed_at", "user_id", "created_by_id", "created_at"], name: "spree_orders_completed_at_user_id_created_by_id_created_at_idx"
    t.index ["customer_id"], name: "index_spree_orders_on_customer_id"
    t.index ["distributor_id"], name: "index_spree_orders_on_distributor_id"
    t.index ["number"], name: "index_orders_on_number"
    t.index ["order_cycle_id"], name: "index_spree_orders_on_order_cycle_id"
    t.index ["user_id"], name: "index_spree_orders_on_user_id"
  end

  create_table "spree_payment_methods", id: :serial, force: :cascade do |t|
    t.string "type", limit: 255
    t.string "name", limit: 255
    t.text "description"
    t.boolean "active", default: true
    t.string "environment", limit: 255, default: "development"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "display_on", limit: 255
  end

  create_table "spree_payments", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "source_id"
    t.string "source_type", limit: 255
    t.integer "payment_method_id"
    t.string "state", limit: 255
    t.string "response_code", limit: 255
    t.string "avs_response", limit: 255
    t.string "identifier", limit: 255
    t.string "cvv_response_code", limit: 255
    t.text "cvv_response_message"
    t.datetime "captured_at"
    t.index ["order_id"], name: "index_spree_payments_on_order_id"
  end

  create_table "spree_paypal_accounts", id: :serial, force: :cascade do |t|
    t.string "email", limit: 255
    t.string "payer_id", limit: 255
    t.string "payer_country", limit: 255
    t.string "payer_status", limit: 255
  end

  create_table "spree_paypal_express_checkouts", id: :serial, force: :cascade do |t|
    t.string "token", limit: 255
    t.string "payer_id", limit: 255
    t.string "transaction_id", limit: 255
    t.string "state", limit: 255, default: "complete"
    t.string "refund_transaction_id", limit: 255
    t.datetime "refunded_at"
    t.string "refund_type", limit: 255
    t.datetime "created_at"
    t.index ["transaction_id"], name: "index_spree_paypal_express_checkouts_on_transaction_id"
  end

  create_table "spree_pending_promotions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "promotion_id"
    t.index ["promotion_id"], name: "index_spree_pending_promotions_on_promotion_id"
    t.index ["user_id"], name: "index_spree_pending_promotions_on_user_id"
  end

  create_table "spree_preferences", id: :serial, force: :cascade do |t|
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "key", limit: 255
    t.string "value_type", limit: 255
    t.index ["key"], name: "index_spree_preferences_on_key", unique: true
  end

  create_table "spree_prices", id: :serial, force: :cascade do |t|
    t.integer "variant_id", null: false
    t.decimal "amount", precision: 10, scale: 2
    t.string "currency", limit: 255
    t.datetime "deleted_at"
    t.index ["variant_id"], name: "index_spree_prices_on_variant_id"
  end

  create_table "spree_product_option_types", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.integer "product_id"
    t.integer "option_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_product_properties", id: :serial, force: :cascade do |t|
    t.string "value", limit: 255
    t.integer "product_id"
    t.integer "property_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0
    t.index ["product_id"], name: "index_product_properties_on_product_id"
  end

  create_table "spree_product_scopes", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.text "arguments"
    t.integer "product_group_id"
    t.index ["name"], name: "index_product_scopes_on_name"
    t.index ["product_group_id"], name: "index_product_scopes_on_product_group_id"
  end

  create_table "spree_products", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, default: "", null: false
    t.text "description"
    t.datetime "available_on"
    t.datetime "deleted_at"
    t.string "permalink", limit: 255
    t.text "meta_description"
    t.string "meta_keywords", limit: 255
    t.integer "tax_category_id"
    t.integer "shipping_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "supplier_id"
    t.boolean "group_buy"
    t.float "group_buy_unit_size"
    t.string "variant_unit", limit: 255
    t.float "variant_unit_scale"
    t.string "variant_unit_name", limit: 255
    t.text "notes"
    t.integer "primary_taxon_id", null: false
    t.boolean "inherits_properties", default: true, null: false
    t.index ["available_on"], name: "index_products_on_available_on"
    t.index ["deleted_at"], name: "index_products_on_deleted_at"
    t.index ["name"], name: "index_products_on_name"
    t.index ["permalink"], name: "index_products_on_permalink"
    t.index ["permalink"], name: "permalink_idx_unique", unique: true
    t.index ["primary_taxon_id"], name: "index_spree_products_on_primary_taxon_id"
    t.index ["supplier_id"], name: "index_spree_products_on_supplier_id"
  end

  create_table "spree_products_promotion_rules", id: false, force: :cascade do |t|
    t.integer "product_id"
    t.integer "promotion_rule_id"
    t.index ["product_id"], name: "index_products_promotion_rules_on_product_id"
    t.index ["promotion_rule_id"], name: "index_products_promotion_rules_on_promotion_rule_id"
  end

  create_table "spree_products_taxons", id: :serial, force: :cascade do |t|
    t.integer "product_id"
    t.integer "taxon_id"
    t.index ["product_id"], name: "index_products_taxons_on_product_id"
    t.index ["taxon_id"], name: "index_products_taxons_on_taxon_id"
  end

  create_table "spree_promotion_action_line_items", id: :serial, force: :cascade do |t|
    t.integer "promotion_action_id"
    t.integer "variant_id"
    t.integer "quantity", default: 1
  end

  create_table "spree_promotion_actions", id: :serial, force: :cascade do |t|
    t.integer "activator_id"
    t.integer "position"
    t.string "type", limit: 255
  end

  create_table "spree_promotion_rules", id: :serial, force: :cascade do |t|
    t.integer "activator_id"
    t.integer "user_id"
    t.integer "product_group_id"
    t.string "type", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_group_id"], name: "index_promotion_rules_on_product_group_id"
    t.index ["user_id"], name: "index_promotion_rules_on_user_id"
  end

  create_table "spree_promotion_rules_users", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "promotion_rule_id"
    t.index ["promotion_rule_id"], name: "index_promotion_rules_users_on_promotion_rule_id"
    t.index ["user_id"], name: "index_promotion_rules_users_on_user_id"
  end

  create_table "spree_properties", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "presentation", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_return_authorizations", id: :serial, force: :cascade do |t|
    t.string "number", limit: 255
    t.string "state", limit: 255
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "order_id"
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "stock_location_id"
    t.datetime "deleted_at"
  end

  create_table "spree_roles", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
  end

  create_table "spree_roles_users", id: false, force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.index ["role_id"], name: "index_roles_users_on_role_id"
    t.index ["user_id"], name: "index_roles_users_on_user_id"
  end

  create_table "spree_shipments", id: :serial, force: :cascade do |t|
    t.string "tracking", limit: 255
    t.string "number", limit: 255
    t.decimal "cost", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "shipped_at"
    t.integer "order_id"
    t.integer "address_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state", limit: 255
    t.integer "stock_location_id"
    t.decimal "included_tax_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "additional_tax_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "adjustment_total", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["number"], name: "index_shipments_on_number"
    t.index ["order_id"], name: "index_spree_shipments_on_order_id", unique: true
  end

  create_table "spree_shipping_categories", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "temperature_controlled", default: false, null: false
  end

  create_table "spree_shipping_method_categories", id: :serial, force: :cascade do |t|
    t.integer "shipping_method_id", null: false
    t.integer "shipping_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shipping_category_id"], name: "index_spree_shipping_method_categories_on_shipping_category_id"
    t.index ["shipping_method_id"], name: "index_spree_shipping_method_categories_on_shipping_method_id"
  end

  create_table "spree_shipping_methods", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_on", limit: 255
    t.datetime "deleted_at"
    t.boolean "require_ship_address", default: true
    t.text "description"
    t.string "tracking_url", limit: 255
    t.integer "tax_category_id"
    t.index ["tax_category_id"], name: "index_spree_shipping_methods_on_tax_category_id"
  end

  create_table "spree_shipping_methods_zones", id: false, force: :cascade do |t|
    t.integer "shipping_method_id"
    t.integer "zone_id"
  end

  create_table "spree_shipping_rates", id: :serial, force: :cascade do |t|
    t.integer "shipment_id"
    t.integer "shipping_method_id"
    t.boolean "selected", default: false
    t.decimal "cost", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shipment_id", "shipping_method_id"], name: "spree_shipping_rates_join_index", unique: true
  end

  create_table "spree_state_changes", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "previous_state", limit: 255
    t.integer "stateful_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stateful_type", limit: 255
    t.string "next_state", limit: 255
    t.index ["stateful_id"], name: "index_spree_state_changes_on_stateful_id"
  end

  create_table "spree_states", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "abbr", limit: 255
    t.integer "country_id"
  end

  create_table "spree_stock_items", id: :serial, force: :cascade do |t|
    t.integer "stock_location_id"
    t.integer "variant_id"
    t.integer "count_on_hand", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "backorderable", default: false
    t.datetime "deleted_at"
    t.integer "lock_version", default: 0
    t.index ["stock_location_id", "variant_id"], name: "stock_item_by_loc_and_var_id"
    t.index ["stock_location_id"], name: "index_spree_stock_items_on_stock_location_id"
    t.index ["variant_id"], name: "index_spree_stock_items_on_variant_id", unique: true
  end

  create_table "spree_stock_locations", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address1", limit: 255
    t.string "address2", limit: 255
    t.string "city", limit: 255
    t.integer "state_id"
    t.string "state_name", limit: 255
    t.integer "country_id"
    t.string "zipcode", limit: 255
    t.string "phone", limit: 255
    t.boolean "active", default: true
    t.boolean "backorderable_default", default: false
    t.boolean "propagate_all_variants", default: true
  end

  create_table "spree_stock_movements", id: :serial, force: :cascade do |t|
    t.integer "stock_item_id"
    t.integer "quantity", default: 0
    t.string "action", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "originator_id"
    t.string "originator_type", limit: 255
    t.index ["stock_item_id"], name: "index_spree_stock_movements_on_stock_item_id"
  end

  create_table "spree_stock_transfers", id: :serial, force: :cascade do |t|
    t.string "type", limit: 255
    t.string "reference", limit: 255
    t.integer "source_location_id"
    t.integer "destination_location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "number", limit: 255
    t.index ["destination_location_id"], name: "index_spree_stock_transfers_on_destination_location_id"
    t.index ["number"], name: "index_spree_stock_transfers_on_number"
    t.index ["source_location_id"], name: "index_spree_stock_transfers_on_source_location_id"
  end

  create_table "spree_tax_categories", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "description", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_default", default: false
    t.datetime "deleted_at"
  end

  create_table "spree_tax_rates", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 8, scale: 5
    t.integer "zone_id"
    t.integer "tax_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "included_in_price", default: false
    t.string "name", limit: 255
    t.boolean "show_rate_in_label", default: true
    t.datetime "deleted_at"
  end

  create_table "spree_taxonomies", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0
  end

  create_table "spree_taxons", id: :serial, force: :cascade do |t|
    t.integer "parent_id"
    t.integer "position", default: 0
    t.string "name", limit: 255, null: false
    t.string "permalink", limit: 255
    t.integer "taxonomy_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lft"
    t.integer "rgt"
    t.text "description"
    t.string "meta_title", limit: 255
    t.string "meta_description", limit: 255
    t.string "meta_keywords", limit: 255
    t.index ["parent_id"], name: "index_taxons_on_parent_id"
    t.index ["permalink"], name: "index_taxons_on_permalink"
    t.index ["taxonomy_id"], name: "index_taxons_on_taxonomy_id"
  end

  create_table "spree_tokenized_permissions", id: :serial, force: :cascade do |t|
    t.integer "permissable_id"
    t.string "permissable_type", limit: 255
    t.string "token", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permissable_id", "permissable_type"], name: "index_tokenized_name_and_type"
  end

  create_table "spree_users", id: :serial, force: :cascade do |t|
    t.string "encrypted_password", limit: 255
    t.string "password_salt", limit: 255
    t.string "email", limit: 255
    t.string "remember_token", limit: 255
    t.string "persistence_token", limit: 255
    t.string "reset_password_token", limit: 255
    t.string "perishable_token", limit: 255
    t.integer "sign_in_count", default: 0, null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_request_at"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.string "login", limit: 255
    t.integer "ship_address_id"
    t.integer "bill_address_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "authentication_token", limit: 255
    t.string "unlock_token", limit: 255
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.string "spree_api_key", limit: 48
    t.datetime "reset_password_sent_at"
    t.string "api_key", limit: 40
    t.integer "enterprise_limit", default: 5, null: false
    t.string "locale", limit: 6
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email", limit: 255
    t.datetime "disabled_at"
    t.boolean "show_api_key_view", default: false, null: false
    t.string "provider"
    t.string "uid"
    t.index ["confirmation_token"], name: "index_spree_users_on_confirmation_token", unique: true
    t.index ["email"], name: "email_idx_unique", unique: true
    t.index ["persistence_token"], name: "index_users_on_persistence_token"
  end

  create_table "spree_variants", id: :serial, force: :cascade do |t|
    t.string "sku", limit: 255, default: "", null: false
    t.decimal "weight", precision: 8, scale: 2
    t.decimal "height", precision: 8, scale: 2
    t.decimal "width", precision: 8, scale: 2
    t.decimal "depth", precision: 8, scale: 2
    t.datetime "deleted_at"
    t.boolean "is_master", default: false
    t.integer "product_id"
    t.integer "position"
    t.string "cost_currency", limit: 255
    t.float "unit_value"
    t.string "unit_description", limit: 255, default: ""
    t.string "display_name", limit: 255
    t.string "display_as", limit: 255
    t.datetime "import_date"
    t.index ["product_id"], name: "index_variants_on_product_id"
    t.index ["sku"], name: "index_spree_variants_on_sku"
    t.check_constraint "unit_value > (0)::double precision", name: "positive_unit_value"
  end

  create_table "spree_zone_members", id: :serial, force: :cascade do |t|
    t.integer "zoneable_id"
    t.string "zoneable_type", limit: 255
    t.integer "zone_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_zones", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "description", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "default_tax", default: false
    t.integer "zone_members_count", default: 0
  end

  create_table "stripe_accounts", id: :serial, force: :cascade do |t|
    t.string "stripe_user_id", limit: 255
    t.string "stripe_publishable_key", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "enterprise_id"
    t.index ["enterprise_id"], name: "index_stripe_accounts_on_enterprise_id", unique: true
  end

  create_table "subscription_line_items", id: :serial, force: :cascade do |t|
    t.integer "subscription_id", null: false
    t.integer "variant_id", null: false
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price_estimate", precision: 10, scale: 2
    t.index ["subscription_id"], name: "index_subscription_line_items_on_subscription_id"
    t.index ["variant_id"], name: "index_subscription_line_items_on_variant_id"
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.integer "shop_id", null: false
    t.integer "customer_id", null: false
    t.integer "schedule_id", null: false
    t.integer "payment_method_id", null: false
    t.integer "shipping_method_id", null: false
    t.datetime "begins_at"
    t.datetime "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bill_address_id", null: false
    t.integer "ship_address_id", null: false
    t.datetime "canceled_at"
    t.datetime "paused_at"
    t.decimal "shipping_fee_estimate", precision: 10, scale: 2
    t.decimal "payment_fee_estimate", precision: 10, scale: 2
    t.index ["bill_address_id"], name: "index_subscriptions_on_bill_address_id"
    t.index ["customer_id"], name: "index_subscriptions_on_customer_id"
    t.index ["payment_method_id"], name: "index_subscriptions_on_payment_method_id"
    t.index ["schedule_id"], name: "index_subscriptions_on_schedule_id"
    t.index ["ship_address_id"], name: "index_subscriptions_on_ship_address_id"
    t.index ["shipping_method_id"], name: "index_subscriptions_on_shipping_method_id"
    t.index ["shop_id"], name: "index_subscriptions_on_shop_id"
  end

  create_table "tag_rules", id: :serial, force: :cascade do |t|
    t.integer "enterprise_id", null: false
    t.string "type", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_default", default: false, null: false
    t.integer "priority", default: 99, null: false
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type", limit: 255
    t.integer "tagger_id"
    t.string "tagger_type", limit: 255
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "terms_of_service_files", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "variant_overrides", id: :serial, force: :cascade do |t|
    t.integer "variant_id", null: false
    t.integer "hub_id", null: false
    t.decimal "price", precision: 10, scale: 2
    t.integer "count_on_hand"
    t.integer "default_stock"
    t.boolean "resettable"
    t.string "sku", limit: 255
    t.boolean "on_demand"
    t.datetime "permission_revoked_at"
    t.datetime "import_date"
    t.index ["variant_id", "hub_id"], name: "index_variant_overrides_on_variant_id_and_hub_id"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", limit: 255, null: false
    t.integer "item_id", null: false
    t.string "event", limit: 255, null: false
    t.string "whodunnit", limit: 255
    t.text "object"
    t.datetime "created_at"
    t.text "custom_data"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "adjustment_metadata", "enterprises", name: "adjustment_metadata_enterprise_id_fk"
  add_foreign_key "adjustment_metadata", "spree_adjustments", column: "adjustment_id", name: "adjustment_metadata_adjustment_id_fk", on_delete: :cascade
  add_foreign_key "coordinator_fees", "enterprise_fees", name: "coordinator_fees_enterprise_fee_id_fk"
  add_foreign_key "coordinator_fees", "order_cycles", name: "coordinator_fees_order_cycle_id_fk"
  add_foreign_key "customers", "enterprises", name: "customers_enterprise_id_fk"
  add_foreign_key "customers", "spree_addresses", column: "bill_address_id", name: "customers_bill_address_id_fk"
  add_foreign_key "customers", "spree_addresses", column: "ship_address_id", name: "customers_ship_address_id_fk"
  add_foreign_key "customers", "spree_users", column: "user_id", name: "customers_user_id_fk"
  add_foreign_key "distributors_payment_methods", "enterprises", column: "distributor_id", name: "distributors_payment_methods_distributor_id_fk"
  add_foreign_key "distributors_payment_methods", "spree_payment_methods", column: "payment_method_id", name: "distributors_payment_methods_payment_method_id_fk"
  add_foreign_key "distributors_shipping_methods", "enterprises", column: "distributor_id", name: "distributors_shipping_methods_distributor_id_fk"
  add_foreign_key "distributors_shipping_methods", "spree_shipping_methods", column: "shipping_method_id", name: "distributors_shipping_methods_shipping_method_id_fk"
  add_foreign_key "enterprise_fees", "enterprises", name: "enterprise_fees_enterprise_id_fk"
  add_foreign_key "enterprise_fees", "spree_tax_categories", column: "tax_category_id", name: "enterprise_fees_tax_category_id_fk"
  add_foreign_key "enterprise_groups", "spree_addresses", column: "address_id", name: "enterprise_groups_address_id_fk"
  add_foreign_key "enterprise_groups", "spree_users", column: "owner_id", name: "enterprise_groups_owner_id_fk"
  add_foreign_key "enterprise_groups_enterprises", "enterprise_groups", name: "enterprise_groups_enterprises_enterprise_group_id_fk"
  add_foreign_key "enterprise_groups_enterprises", "enterprises", name: "enterprise_groups_enterprises_enterprise_id_fk"
  add_foreign_key "enterprise_relationship_permissions", "enterprise_relationships", name: "erp_enterprise_relationship_id_fk"
  add_foreign_key "enterprise_relationships", "enterprises", column: "child_id", name: "enterprise_relationships_child_id_fk"
  add_foreign_key "enterprise_relationships", "enterprises", column: "parent_id", name: "enterprise_relationships_parent_id_fk"
  add_foreign_key "enterprise_roles", "enterprises", name: "enterprise_roles_enterprise_id_fk"
  add_foreign_key "enterprise_roles", "spree_users", column: "user_id", name: "enterprise_roles_user_id_fk"
  add_foreign_key "enterprises", "spree_addresses", column: "address_id", name: "enterprises_address_id_fk"
  add_foreign_key "enterprises", "spree_users", column: "owner_id", name: "enterprises_owner_id_fk"
  add_foreign_key "exchange_fees", "enterprise_fees", name: "exchange_fees_enterprise_fee_id_fk"
  add_foreign_key "exchange_fees", "exchanges", name: "exchange_fees_exchange_id_fk"
  add_foreign_key "exchange_variants", "exchanges", name: "exchange_variants_exchange_id_fk"
  add_foreign_key "exchange_variants", "spree_variants", column: "variant_id", name: "exchange_variants_variant_id_fk"
  add_foreign_key "exchanges", "enterprises", column: "receiver_id", name: "exchanges_receiver_id_fk"
  add_foreign_key "exchanges", "enterprises", column: "sender_id", name: "exchanges_sender_id_fk"
  add_foreign_key "exchanges", "order_cycles", name: "exchanges_order_cycle_id_fk"
  add_foreign_key "order_cycle_schedules", "order_cycles", name: "oc_schedules_order_cycle_id_fk"
  add_foreign_key "order_cycle_schedules", "schedules", name: "oc_schedules_schedule_id_fk"
  add_foreign_key "order_cycles", "enterprises", column: "coordinator_id", name: "order_cycles_coordinator_id_fk"
  add_foreign_key "producer_properties", "enterprises", column: "producer_id", name: "producer_properties_producer_id_fk"
  add_foreign_key "producer_properties", "spree_properties", column: "property_id", name: "producer_properties_property_id_fk"
  add_foreign_key "proxy_orders", "order_cycles", name: "proxy_orders_order_cycle_id_fk"
  add_foreign_key "proxy_orders", "spree_orders", column: "order_id", name: "order_id_fk"
  add_foreign_key "proxy_orders", "subscriptions", name: "proxy_orders_subscription_id_fk"
  add_foreign_key "spree_addresses", "spree_countries", column: "country_id", name: "spree_addresses_country_id_fk"
  add_foreign_key "spree_addresses", "spree_states", column: "state_id", name: "spree_addresses_state_id_fk"
  add_foreign_key "spree_inventory_units", "spree_orders", column: "order_id", name: "spree_inventory_units_order_id_fk", on_delete: :cascade
  add_foreign_key "spree_inventory_units", "spree_return_authorizations", column: "return_authorization_id", name: "spree_inventory_units_return_authorization_id_fk"
  add_foreign_key "spree_inventory_units", "spree_shipments", column: "shipment_id", name: "spree_inventory_units_shipment_id_fk", on_delete: :cascade
  add_foreign_key "spree_inventory_units", "spree_variants", column: "variant_id", name: "spree_inventory_units_variant_id_fk"
  add_foreign_key "spree_line_items", "spree_orders", column: "order_id", name: "spree_line_items_order_id_fk"
  add_foreign_key "spree_line_items", "spree_variants", column: "variant_id", name: "spree_line_items_variant_id_fk"
  add_foreign_key "spree_option_values", "spree_option_types", column: "option_type_id", name: "spree_option_values_option_type_id_fk"
  add_foreign_key "spree_option_values_variants", "spree_option_values", column: "option_value_id", name: "spree_option_values_variants_option_value_id_fk"
  add_foreign_key "spree_option_values_variants", "spree_variants", column: "variant_id", name: "spree_option_values_variants_variant_id_fk"
  add_foreign_key "spree_orders", "customers", name: "spree_orders_customer_id_fk"
  add_foreign_key "spree_orders", "enterprises", column: "distributor_id", name: "spree_orders_distributor_id_fk"
  add_foreign_key "spree_orders", "order_cycles", name: "spree_orders_order_cycle_id_fk"
  add_foreign_key "spree_orders", "spree_addresses", column: "bill_address_id", name: "spree_orders_bill_address_id_fk"
  add_foreign_key "spree_orders", "spree_addresses", column: "ship_address_id", name: "spree_orders_ship_address_id_fk"
  add_foreign_key "spree_orders", "spree_users", column: "user_id", name: "spree_orders_user_id_fk"
  add_foreign_key "spree_payments", "spree_orders", column: "order_id", name: "spree_payments_order_id_fk"
  add_foreign_key "spree_payments", "spree_payment_methods", column: "payment_method_id", name: "spree_payments_payment_method_id_fk"
  add_foreign_key "spree_prices", "spree_variants", column: "variant_id", name: "spree_prices_variant_id_fk"
  add_foreign_key "spree_product_option_types", "spree_option_types", column: "option_type_id", name: "spree_product_option_types_option_type_id_fk"
  add_foreign_key "spree_product_option_types", "spree_products", column: "product_id", name: "spree_product_option_types_product_id_fk"
  add_foreign_key "spree_product_properties", "spree_products", column: "product_id", name: "spree_product_properties_product_id_fk"
  add_foreign_key "spree_product_properties", "spree_properties", column: "property_id", name: "spree_product_properties_property_id_fk"
  add_foreign_key "spree_products", "enterprises", column: "supplier_id", name: "spree_products_supplier_id_fk"
  add_foreign_key "spree_products", "spree_shipping_categories", column: "shipping_category_id", name: "spree_products_shipping_category_id_fk"
  add_foreign_key "spree_products", "spree_tax_categories", column: "tax_category_id", name: "spree_products_tax_category_id_fk"
  add_foreign_key "spree_products", "spree_taxons", column: "primary_taxon_id", name: "spree_products_primary_taxon_id_fk"
  add_foreign_key "spree_products_promotion_rules", "spree_products", column: "product_id", name: "spree_products_promotion_rules_product_id_fk"
  add_foreign_key "spree_products_promotion_rules", "spree_promotion_rules", column: "promotion_rule_id", name: "spree_products_promotion_rules_promotion_rule_id_fk"
  add_foreign_key "spree_products_taxons", "spree_products", column: "product_id", name: "spree_products_taxons_product_id_fk", on_delete: :cascade
  add_foreign_key "spree_products_taxons", "spree_taxons", column: "taxon_id", name: "spree_products_taxons_taxon_id_fk", on_delete: :cascade
  add_foreign_key "spree_promotion_action_line_items", "spree_promotion_actions", column: "promotion_action_id", name: "spree_promotion_action_line_items_promotion_action_id_fk"
  add_foreign_key "spree_promotion_action_line_items", "spree_variants", column: "variant_id", name: "spree_promotion_action_line_items_variant_id_fk"
  add_foreign_key "spree_promotion_actions", "spree_activators", column: "activator_id", name: "spree_promotion_actions_activator_id_fk"
  add_foreign_key "spree_promotion_rules", "spree_activators", column: "activator_id", name: "spree_promotion_rules_activator_id_fk"
  add_foreign_key "spree_return_authorizations", "spree_orders", column: "order_id", name: "spree_return_authorizations_order_id_fk"
  add_foreign_key "spree_roles_users", "spree_roles", column: "role_id", name: "spree_roles_users_role_id_fk"
  add_foreign_key "spree_roles_users", "spree_users", column: "user_id", name: "spree_roles_users_user_id_fk"
  add_foreign_key "spree_shipments", "spree_addresses", column: "address_id", name: "spree_shipments_address_id_fk"
  add_foreign_key "spree_shipments", "spree_orders", column: "order_id", name: "spree_shipments_order_id_fk", on_delete: :cascade
  add_foreign_key "spree_state_changes", "spree_users", column: "user_id", name: "spree_state_changes_user_id_fk"
  add_foreign_key "spree_states", "spree_countries", column: "country_id", name: "spree_states_country_id_fk"
  add_foreign_key "spree_tax_rates", "spree_tax_categories", column: "tax_category_id", name: "spree_tax_rates_tax_category_id_fk"
  add_foreign_key "spree_tax_rates", "spree_zones", column: "zone_id", name: "spree_tax_rates_zone_id_fk"
  add_foreign_key "spree_taxons", "spree_taxonomies", column: "taxonomy_id", name: "spree_taxons_taxonomy_id_fk"
  add_foreign_key "spree_taxons", "spree_taxons", column: "parent_id", name: "spree_taxons_parent_id_fk"
  add_foreign_key "spree_users", "spree_addresses", column: "bill_address_id", name: "spree_users_bill_address_id_fk"
  add_foreign_key "spree_users", "spree_addresses", column: "ship_address_id", name: "spree_users_ship_address_id_fk"
  add_foreign_key "spree_variants", "spree_products", column: "product_id", name: "spree_variants_product_id_fk"
  add_foreign_key "spree_zone_members", "spree_zones", column: "zone_id", name: "spree_zone_members_zone_id_fk"
  add_foreign_key "subscription_line_items", "spree_variants", column: "variant_id", name: "subscription_line_items_variant_id_fk"
  add_foreign_key "subscription_line_items", "subscriptions", name: "subscription_line_items_subscription_id_fk"
  add_foreign_key "subscriptions", "customers", name: "subscriptions_customer_id_fk"
  add_foreign_key "subscriptions", "enterprises", column: "shop_id", name: "subscriptions_shop_id_fk"
  add_foreign_key "subscriptions", "schedules", name: "subscriptions_schedule_id_fk"
  add_foreign_key "subscriptions", "spree_addresses", column: "bill_address_id", name: "subscriptions_bill_address_id_fk"
  add_foreign_key "subscriptions", "spree_addresses", column: "ship_address_id", name: "subscriptions_ship_address_id_fk"
  add_foreign_key "subscriptions", "spree_payment_methods", column: "payment_method_id", name: "subscriptions_payment_method_id_fk"
  add_foreign_key "subscriptions", "spree_shipping_methods", column: "shipping_method_id", name: "subscriptions_shipping_method_id_fk"
  add_foreign_key "variant_overrides", "enterprises", column: "hub_id", name: "variant_overrides_hub_id_fk"
  add_foreign_key "variant_overrides", "spree_variants", column: "variant_id", name: "variant_overrides_variant_id_fk"
end
