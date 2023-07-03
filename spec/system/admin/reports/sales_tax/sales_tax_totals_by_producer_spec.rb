# frozen_string_literal: true

require 'system_helper'

describe "Sales Tax Totals By Producer" do
  #  Scenarion 1: added tax
  #  1 producer
  #  1 distributor
  #  1 product that costs 100$
  #  1 order with 1 line item
  #  the line item match 2 tax rates: country (2.5%) and state (1.5%)
  let!(:table_header){
    [
      "Distributor",
      "Distributor Tax Status",
      "Producer",
      "Producer Tax Status",
      "Order Cycle",
      "Tax Category",
      "Tax Rate Name",
      "Tax Rate",
      "Total excl. Tax ($)",
      "Tax",
      "Total incl. Tax ($)"
    ].join(" ").upcase
  }
  let!(:state_zone){ create(:zone_with_state_member) }
  let!(:country_zone){ create(:zone_with_member) }
  let!(:tax_category){ create(:tax_category) }
  let!(:state_tax_rate){ create(:tax_rate, zone: state_zone, tax_category: tax_category) }
  let!(:country_tax_rate){ create(:tax_rate, zone: country_zone, tax_category: tax_category) }
  let!(:ship_address){ create(:ship_address) }

  let!(:variant){ create(:variant) }
  let!(:product){ variant.product }
  let!(:supplier){ create(:supplier_enterprise) }
  let!(:distributor){ create(:distributor_enterprise_with_tax) }
  let!(:payment_method){ create(:payment_method, :flat_rate) }
  let!(:shipping_method){ create(:shipping_method, :flat_rate) }

  let!(:order){ create(:order_with_distributor, distributor: distributor) }
  let!(:order_cycle){
    create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor],
                                variants: [variant])
  }

  let(:admin){ create(:admin_user) }

  before do
    state_tax_rate.update!({ name: 'State', amount: 0.015 })
    country_tax_rate.update!({ name: 'Country', amount: 0.025 })
    tax_category.update!({ name: 'tax_category' })
    order_cycle.update!(name: "oc1")

    distributor.update!({ name: 'Distributor' })
    distributor.shipping_methods << shipping_method
    distributor.payment_methods << payment_method

    supplier.update!(name: 'Supplier', charges_sales_tax: true)
    product.update!(supplier_id: supplier.id)
    variant.update!(tax_category_id: tax_category.id)
  end

  context 'added tax' do
    before do
      order.line_items.create({ variant: variant, quantity: 1, price: 100 })
      order.update!({
                      order_cycle_id: order_cycle.id,
                      ship_address_id: ship_address.id
                    })

      while !order.completed?
        break unless order.next!
      end
    end

    it "generates the report" do
      login_as admin
      visit admin_reports_path
      click_on 'Sales Tax Totals By Producer'

      expect(page).to have_button("Go")
      click_on "Go"
      expect(page.find("table.report__table thead tr").text).to have_content(table_header)

      expect(page.find("table.report__table tbody").text).to have_content([
        "Distributor",
        "Yes",
        "Supplier",
        "Yes",
        "oc1",
        "tax_category",
        "State",
        "1.5 %",
        "100.0",
        "1.5",
        "101.5"
      ].join(" "))

      expect(page.find("table.report__table tbody").text).to have_content([
        "Distributor",
        "Yes",
        "Supplier",
        "Yes",
        "oc1",
        "tax_category",
        "Country",
        "2.5 %",
        "100.0",
        "2.5",
        "102.5"
      ].join(" "))

      expect(page.find("table.report__table tbody").text).to have_content([
        "TOTAL",
        "100.0",
        "4.0",
        "104.0"
      ].join(" "))
    end
  end

  context 'included tax' do
    before do
      state_tax_rate.update!({ included_in_price: true })
      country_tax_rate.update!({ included_in_price: true })

      order.line_items.create({ variant: variant, quantity: 1, price: 100 })
      order.update!({
                      order_cycle_id: order_cycle.id,
                      ship_address_id: ship_address.id
                    })

      while !order.completed?
        break unless order.next!
      end
    end
    it "generates the report" do
      login_as admin
      visit admin_reports_path
      click_on 'Sales Tax Totals By Producer'

      expect(page).to have_button("Go")
      click_on "Go"
      expect(page.find("table.report__table thead tr").text).to have_content(table_header)

      expect(page.find("table.report__table tbody").text).to have_content([
        "Distributor",
        "Yes",
        "Supplier",
        "Yes",
        "oc1",
        "tax_category",
        "State",
        "1.5 %",
        "96.08",
        "1.48",
        "97.56"
      ].join(" "))

      expect(page.find("table.report__table tbody").text).to have_content([
        "Distributor",
        "Yes",
        "Supplier",
        "Yes",
        "oc1",
        "tax_category",
        "Country",
        "2.5 %",
        "96.08",
        "2.44",
        "98.52"
      ].join(" "))

      expect(page.find("table.report__table tbody").text).to have_content([
        "TOTAL",
        "96.08",
        "3.92",
        "100.0"
      ].join(" "))
    end
  end

  context 'should filter by customer' do
    let!(:order2){ create(:order_with_distributor, distributor: distributor) }
    let!(:customer1){ create(:customer, enterprise: create(:enterprise), user: create(:user)) }
    let!(:customer2){ create(:customer, enterprise: create(:enterprise), user: create(:user)) }
    let!(:customer_email_dropdown_selector){ "#s2id_q_customer_id_in" }
    let!(:country_tax_rate_row){
      [
        "Distributor",
        "Yes",
        "Supplier",
        "Yes",
        "oc1",
        "tax_category",
        "Country",
        "2.5 %",
        "300.0",
        "7.5",
        "307.5"
      ].join(" ")
    }
    let!(:state_tax_rate_row){
      [
        "Distributor",
        "Yes",
        "Supplier",
        "Yes",
        "oc1",
        "tax_category",
        "State",
        "1.5 %",
        "300.0",
        "4.5",
        "304.5"
      ].join(" ")
    }
    let(:summary_row){
      [
        "TOTAL",
        "300.0",
        "12.0",
        "312.0"
      ].join(" ")
    }

    let(:customer1_country_tax_rate_row){
      [
        "Distributor",
        "Yes",
        "Supplier",
        "Yes",
        "oc1",
        "tax_category",
        "Country",
        "2.5 %",
        "100.0",
        "2.5",
        "102.5"
      ].join(" ")
    }
    let(:customer1_state_tax_rate_row){
      [
        "Distributor",
        "Yes",
        "Supplier",
        "Yes",
        "oc1",
        "tax_category",
        "State",
        "1.5 %",
        "100.0",
        "1.5",
        "101.5"
      ].join(" ")
    }
    let(:customer1_summary_row){
      [
        "TOTAL",
        "100.0",
        "4.0",
        "104.0"
      ].join(" ")
    }

    let(:customer2_country_tax_rate_row){
      [
        "Distributor",
        "Yes",
        "Supplier",
        "Yes",
        "oc1",
        "tax_category",
        "Country",
        "2.5 %",
        "200.0",
        "5.0",
        "205.0"
      ].join(" ")
    }
    let(:customer2_state_tax_rate_row){
      [
        "Distributor",
        "Yes",
        "Supplier",
        "Yes",
        "oc1",
        "tax_category",
        "State",
        "1.5 %",
        "200.0",
        "3.0",
        "203.0"
      ].join(" ")
    }
    let(:customer2_summary_row){
      [
        "TOTAL",
        "200.0",
        "8.0",
        "208.0"
      ].join(" ")
    }

    before do
      order.line_items.create({ variant: variant, quantity: 1, price: 100 })
      order.update!({
                      order_cycle_id: order_cycle.id,
                      ship_address_id: customer1.bill_address_id,
                      customer_id: customer1.id
                    })
      while !order.completed?
        break unless order.next!
      end

      order2.line_items.create({ variant: variant, quantity: 1, price: 200 })
      order2.update!({
                       order_cycle_id: order_cycle.id,
                       ship_address_id: customer2.bill_address_id,
                       customer_id: customer2.id
                     })
      while !order2.completed?
        break unless order2.next!
      end
      login_as admin
      visit admin_reports_path
      click_on 'Sales Tax Totals By Producer'
    end

    it "should load all the orders" do
      expect(page).to have_button("Go")
      click_on "Go"

      expect(page.find("table.report__table thead tr").text).to have_content(table_header)
      expect(page.find("table.report__table tbody").text).to have_content(state_tax_rate_row)
      expect(page.find("table.report__table tbody").text).to have_content(country_tax_rate_row)
      expect(page.find("table.report__table tbody").text).to have_content(summary_row)
    end

    it "should filter customer1 orders" do
      page.find(customer_email_dropdown_selector).click
      find('li', text: customer1.email).click

      expect(page).to have_button("Go")
      click_on "Go"

      expect(page.find("table.report__table thead tr").text).to have_content(table_header)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer1_country_tax_rate_row)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer1_state_tax_rate_row)
      expect(page.find("table.report__table tbody").text).to have_content(customer1_summary_row)
    end

    it "should filter customer2 orders" do
      page.find(customer_email_dropdown_selector).click
      find('li', text: customer2.email).click

      expect(page).to have_button("Go")
      click_on "Go"

      expect(page.find("table.report__table thead tr").text).to have_content(table_header)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer2_country_tax_rate_row)
      expect(
        page.find("table.report__table tbody").text
      ).to have_content(customer2_state_tax_rate_row)
      expect(page.find("table.report__table tbody").text).to have_content(customer2_summary_row)
    end

    it "should filter customer1 and customer2 orders" do
      page.find(customer_email_dropdown_selector).click
      find('li', text: customer1.email).click
      page.find(customer_email_dropdown_selector).click
      find('li', text: customer2.email).click
      click_on "Go"

      expect(page.find("table.report__table thead tr").text).to have_content(table_header)
      expect(page.find("table.report__table tbody").text).to have_content(state_tax_rate_row)
      expect(page.find("table.report__table tbody").text).to have_content(country_tax_rate_row)
      expect(page.find("table.report__table tbody").text).to have_content(summary_row)
    end
  end
end
