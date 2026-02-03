# frozen_string_literal: true

RSpec.describe "Admin Reports AJAX Search API" do
  let(:bill_address) { create(:address) }
  let(:ship_address) { create(:address) }
  let(:instructions) { "pick up on thursday please" }
  let(:coordinator1) { create(:distributor_enterprise) }
  let(:supplier1) { create(:supplier_enterprise) }
  let(:supplier2) { create(:supplier_enterprise) }
  let(:supplier3) { create(:supplier_enterprise) }
  let(:distributor1) { create(:distributor_enterprise) }
  let(:distributor2) { create(:distributor_enterprise) }
  let(:product1) { create(:product, price: 12.34, supplier_id: supplier1.id) }
  let(:product2) { create(:product, price: 23.45, supplier_id: supplier2.id) }
  let(:product3) { create(:product, price: 34.56, supplier_id: supplier3.id) }

  let(:ocA) {
    create(:simple_order_cycle, coordinator: coordinator1,
                                distributors: [distributor1, distributor2],
                                suppliers: [supplier1, supplier2, supplier3],
                                variants: [product1.variants.first, product3.variants.first])
  }
  let(:ocB) {
    create(:simple_order_cycle, coordinator: coordinator1,
                                distributors: [distributor1, distributor2],
                                suppliers: [supplier1, supplier2, supplier3],
                                variants: [product2.variants.first])
  }

  let(:orderA1) do
    order = create(:order, distributor: distributor1, bill_address:,
                           ship_address:, special_instructions: instructions,
                           order_cycle: ocA)
    order.line_items << create(:line_item, variant: product1.variants.first)
    order.line_items << create(:line_item, variant: product3.variants.first)
    order.finalize!
    order.save
    order
  end

  let(:orderA2) do
    order = create(:order, distributor: distributor2, bill_address:,
                           ship_address:, special_instructions: instructions,
                           order_cycle: ocA)
    order.line_items << create(:line_item, variant: product2.variants.first)
    order.finalize!
    order.save
    order
  end

  let(:orderB1) do
    order = create(:order, distributor: distributor1, bill_address:,
                           ship_address:, special_instructions: instructions,
                           order_cycle: ocB)
    order.line_items << create(:line_item, variant: product1.variants.first)
    order.line_items << create(:line_item, variant: product3.variants.first)
    order.finalize!
    order.save
    order
  end

  context "AJAX Search" do
    let(:enterprise_fee1) {
      create(:enterprise_fee, name: "Delivery Fee", enterprise: distributor1)
    }
    let(:enterprise_fee2) { create(:enterprise_fee, name: "Admin Fee", enterprise: distributor2) }

    before do
      login_as create(:admin_user)
      orderA1.adjustments.create!(
        originator: enterprise_fee1,
        label: "Delivery Fee",
        amount: 5.0,
        state: "finalized",
        order: orderA1
      )
      orderB1.adjustments.create!(
        originator: enterprise_fee2,
        label: "Admin Fee",
        amount: 3.0,
        state: "finalized",
        order: orderB1
      )
    end

    describe "GET /admin/reports/search_enterprise_fees" do
      it "returns paginated JSON with enterprise fees ordered by name" do
        get "/admin/reports/search_enterprise_fees", params: {
          report_type: :enterprise_fee_summary,
          report_subtype: :enterprise_fees_with_tax_report_by_order
        }

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        names = json_response["results"].pluck("label")
        expect(names).to eq(['Admin Fee', 'Delivery Fee'])
        expect(json_response["pagination"]["more"]).to be false
      end

      it "paginates results and sets more flag correctly with more than 30 records" do
        create_list(:enterprise_fee, 35, enterprise: distributor1) do |fee, i|
          index = (i + 1).to_s.rjust(2, "0")
          fee.update!(name: "Fee #{index}")
          orderA1.adjustments.create!(
            originator: fee,
            label: "Fee #{index}",
            amount: 1.0,
            state: "finalized",
            order: orderA1
          )
        end

        get "/admin/reports/search_enterprise_fees", params: {
          report_type: :enterprise_fee_summary,
          report_subtype: :enterprise_fees_with_tax_report_by_order,
          page: 1
        }

        json_response = response.parsed_body
        expect(json_response["results"].length).to eq(30)
        expect(json_response["pagination"]["more"]).to be true

        get "/admin/reports/search_enterprise_fees", params: {
          report_type: :enterprise_fee_summary,
          report_subtype: :enterprise_fees_with_tax_report_by_order,
          page: 2
        }

        json_response = response.parsed_body
        expect(json_response["results"].length).to eq(7)
        expect(json_response["pagination"]["more"]).to be false
      end
    end

    describe "GET /admin/reports/search_enterprise_fee_owners" do
      it "returns paginated JSON with unique enterprise owners ordered by name" do
        distributor1.update!(name: "Zebra Farm")
        distributor2.update!(name: "Alpha Market")

        get "/admin/reports/search_enterprise_fee_owners", params: {
          report_type: :enterprise_fee_summary,
          report_subtype: :enterprise_fees_with_tax_report_by_order
        }

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        names = json_response["results"].pluck("label")
        expect(names).to eq(['Alpha Market', 'Zebra Farm'])
        expect(json_response["pagination"]["more"]).to be false
      end
    end

    describe "GET /admin/reports/search_order_customers" do
      it "filters customers by email and returns paginated results" do
        customer1 = create(:customer, email: "alice@example.com", enterprise: distributor1)
        customer2 = create(:customer, email: "bob@example.com", enterprise: distributor1)
        orderA1.update!(customer: customer1)
        orderA2.update!(customer: customer2)

        get "/admin/reports/search_order_customers", params: {
          report_type: :enterprise_fee_summary,
          report_subtype: :enterprise_fees_with_tax_report_by_order,
          q: "alice"
        }

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(["alice@example.com"])
        expect(json_response["pagination"]["more"]).to be false
      end

      it "paginates customers and sets more flag correctly with more than 30 records" do
        create_list(:customer, 35, enterprise: distributor1) do |customer, i|
          customer.update!(
            email: "customer#{(i + 1).to_s.rjust(2, '0')}@example.com"
          )
          order = create(
            :order,
            distributor: distributor1,
            order_cycle: ocA,
            customer: customer
          )
          order.line_items << create(
            :line_item,
            variant: product1.variants.first
          )
          order.finalize!
        end

        get "/admin/reports/search_order_customers", params: {
          report_type: :enterprise_fee_summary,
          report_subtype: :enterprise_fees_with_tax_report_by_order,
          page: 1
        }

        json_response = response.parsed_body
        expect(json_response["results"].length).to eq(30)
        expect(json_response["pagination"]["more"]).to be true

        get "/admin/reports/search_order_customers", params: {
          report_type: :enterprise_fee_summary,
          report_subtype: :enterprise_fees_with_tax_report_by_order,
          page: 2
        }

        json_response = response.parsed_body
        expect(json_response["results"].length).to eq(5)
        expect(json_response["pagination"]["more"]).to be false
      end
    end

    describe "GET /admin/reports/search_order_cycles" do
      it "filters order cycles by name and orders by close date" do
        ocA.update!(name: "Winter Market")
        ocB.update!(name: "Summer Market")

        get "/admin/reports/search_order_cycles", params: {
          report_type: :enterprise_fee_summary,
          report_subtype: :enterprise_fees_with_tax_report_by_order,
          q: "Winter"
        }

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(["Winter Market"])
        expect(json_response["pagination"]["more"]).to be false
      end
    end

    describe "GET /admin/reports/search_distributors" do
      it "filters distributors by name" do
        distributor1.update!(name: "Alpha Farm")
        distributor2.update!(name: "Beta Market")

        get "/admin/reports/search_distributors", params: {
          report_type: :enterprise_fee_summary,
          report_subtype: :enterprise_fees_with_tax_report_by_order,
          q: "Alpha"
        }

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(["Alpha Farm"])
        expect(json_response["pagination"]["more"]).to be false
      end

      it "paginates distributors and sets more flag correctly with more than 30 records" do
        create_list(:distributor_enterprise, 35)

        get "/admin/reports/search_distributors", params: {
          report_type: :enterprise_fee_summary,
          report_subtype: :enterprise_fees_with_tax_report_by_order,
          page: 1
        }

        json_response = response.parsed_body
        expect(json_response["results"].length).to eq(30)
        expect(json_response["pagination"]["more"]).to be true

        get "/admin/reports/search_distributors", params: {
          report_type: :enterprise_fee_summary,
          report_subtype: :enterprise_fees_with_tax_report_by_order,
          page: 2
        }

        json_response = response.parsed_body
        expect(json_response["results"].length).to be > 0
        expect(json_response["pagination"]["more"]).to be false
      end
    end
  end
end
