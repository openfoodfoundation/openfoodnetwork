# frozen_string_literal: true

require 'system_helper'

describe "Enterprise Summary Fee with Tax Report By Order" do
  #   1 order cycle the has:
  #     - coordinator fees price 20
  #     - incoming exchange fees 15
  #     - outgoing exchange fees 10
  #   tax
  #       country: 2.5%
  #       state: 1.5%

  let!(:table_header){
    [
      "Distributor",
      "Order Cycle",
      "Order Number",
      "Name",
      "Type",
      "Owner",
      "Tax Category",
      "Tax Rate Name",
      "Tax Rate",
      "Total excl. tax ($)",
      "Tax",
      "Total incl. tax ($)",
      "First Name",
      "Last Name",
      "Customer Code",
      "Customer Email"
    ].join(" ").upcase
  }

  let!(:state_zone){ create(:zone_with_state_member) }
  let!(:country_zone){ create(:zone_with_member) }
  let!(:tax_category){ create(:tax_category, name: 'tax_category') }
  let!(:state_tax_rate){
    create(:tax_rate, zone: state_zone, tax_category: tax_category, name: 'State', amount: 0.015)
  }
  let!(:country_tax_rate){
    create(:tax_rate, zone: country_zone, tax_category: tax_category, name: 'Country',
                      amount: 0.025)
  }
  let!(:ship_address){ create(:ship_address) }

  let!(:variant){ create(:variant) }
  let!(:product){ variant.product }
  let!(:distributor){ create(:distributor_enterprise_with_tax, name: 'Distributor') }
  let!(:supplier){ create(:supplier_enterprise, name: 'Supplier', charges_sales_tax: true) }
  let!(:payment_method){ create(:payment_method, :flat_rate) }
  let!(:shipping_method){ create(:shipping_method, :flat_rate) }

  let!(:order){ create(:order_with_distributor, distributor: distributor, number: order_number) }
  let!(:order_cycle){
    create(:simple_order_cycle, name: "oc1", suppliers: [supplier], distributors: [distributor],
                                variants: [variant])
  }

  let(:admin){ create(:admin_user) }

  let!(:coordinator_fees){
    create(:enterprise_fee, :flat_rate, enterprise: distributor, amount: 20,
                                        name: 'Adminstration',
                                        fee_type: 'admin',
                                        tax_category: tax_category)
  }
  let!(:supplier_fees){
    create(:enterprise_fee, :flat_rate, enterprise: supplier, amount: 15,
                                        name: 'Transport',
                                        fee_type: 'transport',
                                        tax_category: tax_category)
  }
  let!(:distributor_fee){
    create(:enterprise_fee, :flat_rate, enterprise: distributor, amount: 10,
                                        name: 'Packing',
                                        fee_type: 'packing',
                                        tax_category: tax_category)
  }

  let!(:customer_first_name){ "Customer First Name" }
  let!(:customer_last_name){ "Customer Last Name" }
  let!(:customer_code){ "CUS_CODE" }
  let!(:customer_email){ "customer1@example.com" }
  let!(:order_number){ "ORDER_NUMBER_1" }

  before do
    order_cycle.coordinator_fees << coordinator_fees
    order_cycle.exchanges.incoming.first.exchange_fees.create!(enterprise_fee: supplier_fees)
    order_cycle.exchanges.outgoing.first.exchange_fees.create!(enterprise_fee: distributor_fee)

    distributor.shipping_methods << shipping_method
    distributor.payment_methods << payment_method

    product.update!({
                      tax_category_id: tax_category.id,
                      supplier_id: supplier.id
                    })
  end

  context 'added tax' do
    before do
      order.line_items.create({ variant: variant, quantity: 1, price: 100 })
      order.update!({
                      order_cycle_id: order_cycle.id,
                      ship_address_id: ship_address.id
                    })
      # This will load the enterprise fees from the order cycle.
      # This is needed because the order instance was created
      # independently of the order_cycle.
      # order.reload
      order.recreate_all_fees!
      OrderWorkflow.new(order).complete!

      order.customer.update!({
                               first_name: customer_first_name,
                               last_name: customer_last_name,
                               code: customer_code,
                               email: customer_email
                             })
    end

    let(:coordinator_state_tax){
      ["Distributor", "oc1", order_number, "Adminstration", "admin", "Distributor",
       "tax_category", "State", "0.015", "20.0", "0.3", "20.3",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }
    let(:coordinator_country_tax){
      ["Distributor", "oc1", order_number, "Adminstration", "admin", "Distributor",
       "tax_category", "Country", "0.025", "20.0", "0.5", "20.5",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }

    let(:supplier_state_tax){
      ["Distributor", "oc1", order_number, "Transport", "transport", "Supplier",
       "tax_category", "State", "0.015", "15.0", "0.23", "15.23",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }
    let(:supplier_country_tax){
      ["Distributor", "oc1", order_number, "Transport", "transport", "Supplier",
       "tax_category", "Country", "0.025", "15.0", "0.38", "15.38",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }

    let(:distributor_state_tax){
      ["Distributor", "oc1", order_number, "Packing", "packing", "Distributor",
       "tax_category", "State", "0.015", "10.0", "0.15", "10.15",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }
    let(:distributor_country_tax){
      ["Distributor", "oc1", order_number, "Packing", "packing", "Distributor",
       "tax_category", "Country", "0.025", "10.0", "0.25", "10.25",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }

    let(:summary_row){
      ["TOTAL", "45.0", "1.81", "46.81",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }

    it 'generates the report' do
      login_as admin
      visit admin_reports_path
      click_on I18n.t("admin.reports.enterprise_fees_with_tax_report_by_order")

      expect(page).to have_button("Go")
      click_on "Go"

      expect(page.find("table.report__table thead tr").text).to have_content(table_header)

      expect(page.find("table.report__table tbody").text).to have_content(supplier_state_tax)
      expect(page.find("table.report__table tbody").text).to have_content(supplier_country_tax)
      expect(page.find("table.report__table tbody").text).to have_content(distributor_state_tax)
      expect(page.find("table.report__table tbody").text).to have_content(distributor_country_tax)
      expect(page.find("table.report__table tbody").text).to have_content(coordinator_state_tax)
      expect(page.find("table.report__table tbody").text).to have_content(coordinator_country_tax)
      expect(page.find("table.report__table tbody").text).to have_content(summary_row)
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
      order.recreate_all_fees!
      OrderWorkflow.new(order).complete!

      order.customer.update!({
                               first_name: customer_first_name,
                               last_name: customer_last_name,
                               code: customer_code,
                               email: customer_email
                             })
    end

    let(:coordinator_state_tax){
      ["Distributor", "oc1", order_number, "Adminstration", "admin", "Distributor",
       "tax_category", "State", "0.015", "19.21", "0.3", "19.51",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }
    let(:coordinator_country_tax){
      ["Distributor", "oc1", order_number, "Adminstration", "admin", "Distributor",
       "tax_category", "Country", "0.025", "19.21", "0.49", "19.7",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }

    let(:supplier_state_tax){
      ["Distributor", "oc1", order_number, "Transport", "transport", "Supplier",
       "tax_category", "State", "0.015", "14.41", "0.22", "14.63",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }
    let(:supplier_country_tax){
      ["Distributor", "oc1", order_number, "Transport", "transport", "Supplier",
       "tax_category", "Country", "0.025", "14.41", "0.37", "14.78",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }

    let(:distributor_state_tax){
      ["Distributor", "oc1", order_number, "Packing", "packing", "Distributor",
       "tax_category", "State", "0.015", "9.61", "0.15", "9.76",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }
    let(:distributor_country_tax){
      ["Distributor", "oc1", order_number, "Packing", "packing", "Distributor",
       "tax_category", "Country", "0.025", "9.61", "0.24", "9.85",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }

    let(:summary_row){
      ["TOTAL", "43.23", "1.77", "45.0",
       customer_first_name, customer_last_name, customer_code, customer_email].join(" ")
    }

    it 'generates the report' do
      login_as admin
      visit admin_reports_path
      click_on I18n.t("admin.reports.enterprise_fees_with_tax_report_by_order")

      expect(page).to have_button("Go")
      click_on "Go"

      expect(page.find("table.report__table thead tr").text).to have_content(table_header)

      expect(page.find("table.report__table tbody").text).to have_content(supplier_state_tax)
      expect(page.find("table.report__table tbody").text).to have_content(supplier_country_tax)
      expect(page.find("table.report__table tbody").text).to have_content(distributor_state_tax)
      expect(page.find("table.report__table tbody").text).to have_content(distributor_country_tax)
      expect(page.find("table.report__table tbody").text).to have_content(coordinator_state_tax)
      expect(page.find("table.report__table tbody").text).to have_content(coordinator_country_tax)
      expect(page.find("table.report__table tbody").text).to have_content(summary_row)
    end
  end
end
