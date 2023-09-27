# frozen_string_literal: true

require 'system_helper'

def fill_in_subscription_basic_details
  select2_select customer.email, from: "customer_id"
  select2_select schedule.name, from: "schedule_id"
  select2_select payment_method.name, from: "payment_method_id"
  select2_select shipping_method.name, from: "shipping_method_id"

  find_field("begins_at").click
  choose_today_from_datepicker
end

def expect_not_in_open_or_upcoming_order_cycle_warning(count)
  expect(page).to have_content(variant_not_in_open_or_upcoming_order_cycle_warning, count:)
end

def add_variant_to_subscription(variant, quantity)
  row_count = all("#subscription-line-items .item").length
  variant_name = if variant.full_name.present?
                   "#{variant.name} - #{variant.full_name}"
                 else
                   variant.name
                 end
  select2_select variant.name, from: "add_variant_id", search: true, select_text: variant_name
  fill_in "add_quantity", with: quantity
  click_link "Add"
  expect(page).to have_selector("#subscription-line-items .item", count: row_count + 1)
end

def variant_not_in_open_or_upcoming_order_cycle_warning
  'There are no open or upcoming order cycles for this product.'
end
