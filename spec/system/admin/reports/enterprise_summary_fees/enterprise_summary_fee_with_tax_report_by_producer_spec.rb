# frozen_string_literal: true

require 'system_helper'

describe "Enterprise Summary Fee with Tax Report By Producer" do
  #   1 order cycle has:
  #     - coordinator fees price 20
  #     - incoming exchange fees 15
  #     - outgoing exchange fees 10
  #     - cost of line items     100
  #   tax
  #       country: 2.5%
  #       state: 1.5%

  let!(:table_header){
    ["Distributor", "Producer", "Producer Tax Status", "Order Cycle", "Name", "Type", "Owner",
     "Tax Category", "Tax Rate Name", "Tax Rate", "Total excl. tax ($)", "Tax",
     "Total incl. tax ($)"].join(" ").upcase
  }

  let!(:state_zone){ create(:zone_with_state_member) }
  let!(:country_zone){ create(:zone_with_member) }
  let!(:tax_category){ create(:tax_category, name: 'tax_category') }
  let!(:state_tax_rate){
    create(:tax_rate, zone: state_zone, tax_category: tax_category,
                      name: 'State', amount: 0.015)
  }
  let!(:country_tax_rate){
    create(:tax_rate, zone: country_zone, tax_category: tax_category,
                      name: 'Country', amount: 0.025)
  }
  let!(:ship_address){ create(:ship_address) }

  let!(:variant){ create(:variant, tax_category: tax_category) }
  let!(:product){ variant.product }
  let!(:distributor){ create(:distributor_enterprise_with_tax, name: 'Distributor') }
  let!(:supplier){ create(:supplier_enterprise, name: 'Supplier', charges_sales_tax: true) }
  let!(:payment_method){ create(:payment_method, :flat_rate) }
  let!(:shipping_method){ create(:shipping_method, :flat_rate) }

  let!(:order){ create(:order_with_distributor, distributor: distributor) }
  let!(:order_cycle){
    create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor],
                                variants: [variant], name: "oc1")
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
    #   1 order cycle has:
    #     - coordinator fees  (20) 1.5% = 0.30, 2.5% = 0.50
    #     - incoming exchange (15) 1.5% = 0.23, 2.5% = 0.38
    #     - outgoing exchange (10) 1.5% = 0.15, 2.5% = 0.25
    #     - line items       (100) 1.5% = 1.50, 2.5% = 2.50

    before do
      order.line_items.create({ variant: variant, quantity: 1, price: 100 })
      order.update!({
                      order_cycle_id: order_cycle.id,
                      ship_address_id: ship_address.id
                    })
      # This will load the enterprise fees from the order cycle.
      # This is needed because the order instance was created
      # independently of the order_cycle.
      order.recreate_all_fees!
      while !order.completed?
        break unless order.next!
      end
    end

    let(:coordinator_state_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Adminstration", "admin", "Distributor",
       "tax_category", "State", "0.015", "20.0", "0.3", "20.3"].join(" ")
    }
    let(:coordinator_country_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Adminstration", "admin", "Distributor",
       "tax_category", "Country", "0.025", "20.0", "0.5", "20.5"].join(" ")
    }

    let(:supplier_state_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Transport", "transport", "Supplier",
       "tax_category", "State", "0.015", "15.0", "0.23", "15.23"].join(" ")
    }
    let(:supplier_country_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Transport", "transport", "Supplier",
       "tax_category", "Country", "0.025", "15.0", "0.38", "15.38"].join(" ")
    }

    let(:distributor_state_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Packing", "packing", "Distributor",
       "tax_category", "State", "0.015", "10.0", "0.15", "10.15"].join(" ")
    }
    let(:distributor_country_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Packing", "packing", "Distributor",
       "tax_category", "Country", "0.025", "10.0", "0.25", "10.25"].join(" ")
    }

    let(:cost_of_produce){
      ["Distributor", "Supplier", "Yes", "oc1", "Cost of produce", "line items", "Supplier",
       "100.0", "4.0", "104.0"].join(" ")
    }
    let(:summary_row){
      [
        "TOTAL", # Fees and line items
        "145.0", # Tax excl: 20 + 15 + 10 + 100
        "5.81",  # Tax     : (0.30 + 0.50) + (0.23 + 0.38) + (0.15 + 0.25) + (1.50 + 2.50)
        "150.81" # Tax incl: 145.00 + 5.81
      ].join(" ")
    }

    it 'generates the report' do
      login_as admin
      visit admin_reports_path
      click_on I18n.t("admin.reports.enterprise_fees_with_tax_report_by_producer")

      expect(page).to have_button("Go")
      click_on "Go"

      expect(page.find("table.report__table thead tr")).to have_content(table_header)

      table = page.find("table.report__table tbody")
      expect(table).to have_content(supplier_state_tax)
      expect(table).to have_content(supplier_country_tax)
      expect(table).to have_content(distributor_state_tax)
      expect(table).to have_content(distributor_country_tax)
      expect(table).to have_content(coordinator_state_tax)
      expect(table).to have_content(coordinator_country_tax)
      expect(table).to have_content(cost_of_produce)
      expect(table).to have_content(summary_row)
    end

    context "filtering" do
      let(:fee_name_selector){ "#s2id_q_enterprise_fee_id_in" }
      let(:fee_owner_selector){ "#s2id_q_enterprise_fee_owner_id_in" }

      let(:summary_row_after_filtering_by_fee_name){
        ["TOTAL", "120.0", "4.8", "124.8"].join(" ")
      }

      let(:summary_row_after_filtering_by_fee_owner){
        ["TOTAL", "115.0", "4.61", "119.61"].join(" ")
      }

      it "should filter by fee name" do
        login_as admin
        visit admin_reports_path
        click_on I18n.t("admin.reports.enterprise_fees_with_tax_report_by_producer")

        page.find(fee_name_selector).click
        find('li', text: coordinator_fees.name).click

        expect(page).to have_button("Go")
        click_on "Go"

        expect(page.find("table.report__table thead tr")).to have_content(table_header)

        table = page.find("table.report__table tbody")
        expect(table).to_not have_content(supplier_state_tax)
        expect(table).to_not have_content(supplier_country_tax)
        expect(table).to_not have_content(distributor_state_tax)
        expect(table).to_not have_content(distributor_country_tax)
        expect(table).to have_content(coordinator_state_tax)
        expect(table).to have_content(coordinator_country_tax)
        expect(table).to have_content(cost_of_produce)
        expect(table).to have_content(summary_row_after_filtering_by_fee_name)
      end

      it "should filter by fee owner" do
        login_as admin
        visit admin_reports_path
        click_on I18n.t("admin.reports.enterprise_fees_with_tax_report_by_producer")

        page.find(fee_owner_selector).click
        find('li', text: supplier.name).click

        expect(page).to have_button("Go")
        click_on "Go"

        expect(page.find("table.report__table thead tr")).to have_content(table_header)

        table = page.find("table.report__table tbody")
        expect(table).to have_content(supplier_state_tax)
        expect(table).to have_content(supplier_country_tax)
        expect(table).to_not have_content(distributor_state_tax)
        expect(table).to_not have_content(distributor_country_tax)
        expect(table).to_not have_content(coordinator_state_tax)
        expect(table).to_not have_content(coordinator_country_tax)
        expect(table).to have_content(cost_of_produce)
        expect(table).to have_content(summary_row_after_filtering_by_fee_owner)
      end
    end
  end

  context 'included tax' do
    #   1 order cycle has:
    #     - coordinator fees  (20) 1.5% = 0.30, 2.5% = 0.50
    #     - incoming exchange (15) 1.5% = 0.23, 2.5% = 0.38
    #     - outgoing exchange (10) 1.5% = 0.15, 2.5% = 0.25
    #     - line items       (100) 1.5% = 1.50, 2.5% = 2.50

    before do
      state_tax_rate.update!({ included_in_price: true })
      country_tax_rate.update!({ included_in_price: true })

      order.line_items.create({ variant: variant, quantity: 1, price: 100 })
      order.update!({
                      order_cycle_id: order_cycle.id,
                      ship_address_id: ship_address.id
                    })
      order.recreate_all_fees!
      while !order.completed?
        break unless order.next!
      end
    end

    let(:coordinator_state_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Adminstration", "admin", "Distributor",
       "tax_category", "State", "0.015", "19.21", "0.3", "19.51"].join(" ")
    }
    let(:coordinator_country_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Adminstration", "admin", "Distributor",
       "tax_category", "Country", "0.025", "19.21", "0.49", "19.7"].join(" ")
    }

    let(:supplier_state_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Transport", "transport", "Supplier",
       "tax_category", "State", "0.015", "14.41", "0.22", "14.63"].join(" ")
    }
    let(:supplier_country_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Transport", "transport", "Supplier",
       "tax_category", "Country", "0.025", "14.41", "0.37", "14.78"].join(" ")
    }

    let(:distributor_state_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Packing", "packing", "Distributor",
       "tax_category", "State", "0.015", "9.61", "0.15", "9.76"].join(" ")
    }
    let(:distributor_country_tax){
      ["Distributor", "Supplier", "Yes", "oc1", "Packing", "packing", "Distributor",
       "tax_category", "Country", "0.025", "9.61", "0.24", "9.85"].join(" ")
    }

    let(:cost_of_produce){
      ["Distributor", "Supplier", "Yes", "oc1", "Cost of produce", "line items", "Supplier",
       "96.08", "3.92", "100.0"].join(" ")
    }
    let(:summary_row){
      ["TOTAL", "139.31", "5.69", "145.0"].join(" ")
    }

    it 'generates the report' do
      login_as admin
      visit admin_reports_path
      click_on I18n.t("admin.reports.enterprise_fees_with_tax_report_by_producer")

      expect(page).to have_button("Go")
      click_on "Go"

      expect(page.find("table.report__table thead tr")).to have_content(table_header)

      table = page.find("table.report__table tbody")
      expect(table).to have_content(supplier_state_tax)
      expect(table).to have_content(supplier_country_tax)
      expect(table).to have_content(distributor_state_tax)
      expect(table).to have_content(distributor_country_tax)
      expect(table).to have_content(coordinator_state_tax)
      expect(table).to have_content(coordinator_country_tax)
      expect(table).to have_content(cost_of_produce)
      expect(table).to have_content(summary_row)
    end
  end
end
