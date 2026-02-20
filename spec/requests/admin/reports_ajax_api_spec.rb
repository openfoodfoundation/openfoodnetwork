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

  let(:enterprise_fee1) { create(:enterprise_fee, name: "Delivery Fee", enterprise: distributor1) }
  let(:enterprise_fee2) { create(:enterprise_fee, name: "Admin Fee", enterprise: distributor2) }

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

  let(:base_params) do
    {
      report_type: :enterprise_fee_summary,
      report_subtype: :enterprise_fees_with_tax_report_by_order
    }
  end

  def create_adjustment(order, fee, amount)
    order.adjustments.create!(
      originator: fee,
      label: fee.name,
      amount:,
      state: "finalized",
      order:
    )
  end

  context "when user is an admin" do
    before do
      login_as create(:admin_user)
      create_adjustment(orderA1, enterprise_fee1, 5.0)
      create_adjustment(orderB1, enterprise_fee2, 3.0)
    end

    describe "GET /admin/reports/search_enterprise_fees" do
      it "returns enterprise fees sorted alphabetically by name" do
        get "/admin/reports/search_enterprise_fees", params: base_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response["results"].pluck("label")).to eq(['Admin Fee', 'Delivery Fee'])
        expect(json_response["pagination"]["more"]).to be false
      end

      context "with more than 30 records" do
        before do
          create_list(:enterprise_fee, 35, enterprise: distributor1) do |fee, i|
            index = (i + 1).to_s.rjust(2, "0")
            fee.update!(name: "Fee #{index}")
            create_adjustment(orderA1, fee, 1.0)
          end
        end

        it "returns first page with 30 results and more flag as true" do
          get "/admin/reports/search_enterprise_fees", params: base_params.merge(page: 1)

          json_response = response.parsed_body
          expect(json_response["results"].length).to eq(30)
          expect(json_response["pagination"]["more"]).to be true
        end

        it "returns remaining results on second page with more flag as false" do
          get "/admin/reports/search_enterprise_fees", params: base_params.merge(page: 2)

          json_response = response.parsed_body
          expect(json_response["results"].length).to eq(7)
          expect(json_response["pagination"]["more"]).to be false
        end
      end
    end

    describe "GET /admin/reports/search_enterprise_fee_owners" do
      it "returns unique enterprise fee owners sorted alphabetically by name" do
        distributor1.update!(name: "Zebra Farm")
        distributor2.update!(name: "Alpha Market")

        get "/admin/reports/search_enterprise_fee_owners", params: base_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response["results"].pluck("label")).to eq(['Alpha Market', 'Zebra Farm'])
        expect(json_response["pagination"]["more"]).to be false
      end
    end

    describe "GET /admin/reports/search_order_customers" do
      let!(:customer1) { create(:customer, email: "alice@example.com", enterprise: distributor1) }
      let!(:customer2) { create(:customer, email: "bob@example.com", enterprise: distributor1) }

      before do
        orderA1.update!(customer: customer1)
        orderA2.update!(customer: customer2)
      end

      it "returns all customers sorted by email" do
        get "/admin/reports/search_order_customers", params: base_params

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(["alice@example.com",
                                                               "bob@example.com"])
        expect(json_response["pagination"]["more"]).to be false
      end

      it "filters customers by email query" do
        get "/admin/reports/search_order_customers", params: base_params.merge(q: "alice")

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(["alice@example.com"])
        expect(json_response["pagination"]["more"]).to be false
      end

      context "with more than 30 customers" do
        before do
          create_list(:customer, 35, enterprise: distributor1) do |customer, i|
            customer.update!(email: "customer#{(i + 1).to_s.rjust(2, '0')}@example.com")
            order = create(:order, distributor: distributor1, order_cycle: ocA, customer:)
            order.line_items << create(:line_item, variant: product1.variants.first)
            order.finalize!
          end
        end

        it "returns first page with 30 results and more flag as true" do
          get "/admin/reports/search_order_customers", params: base_params.merge(page: 1)

          json_response = response.parsed_body
          expect(json_response["results"].length).to eq(30)
          expect(json_response["pagination"]["more"]).to be true
        end

        it "returns remaining results on second page with more flag as false" do
          get "/admin/reports/search_order_customers", params: base_params.merge(page: 2)

          json_response = response.parsed_body
          expect(json_response["results"].length).to eq(7)
          expect(json_response["pagination"]["more"]).to be false
        end
      end
    end

    describe "GET /admin/reports/search_order_cycles" do
      before do
        ocA.update!(name: "Winter Market")
        ocB.update!(name: "Summer Market")
      end

      it "returns order cycles sorted by close date" do
        get "/admin/reports/search_order_cycles", params: base_params

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(["Summer Market", "Winter Market"])
        expect(json_response["pagination"]["more"]).to be false
      end

      it "filters order cycles by name query" do
        get "/admin/reports/search_order_cycles", params: base_params.merge(q: "Winter")

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(["Winter Market"])
        expect(json_response["pagination"]["more"]).to be false
      end
    end

    describe "GET /admin/reports/search_distributors" do
      before do
        distributor1.update!(name: "Alpha Farm")
        distributor2.update!(name: "Beta Market")
      end

      it "filters distributors by name query" do
        get "/admin/reports/search_distributors", params: base_params.merge(q: "Alpha")

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(["Alpha Farm"])
        expect(json_response["pagination"]["more"]).to be false
      end

      context "with more than 30 distributors" do
        before { create_list(:distributor_enterprise, 35) }

        it "returns first page with 30 results and more flag as true" do
          get "/admin/reports/search_distributors", params: base_params.merge(page: 1)

          json_response = response.parsed_body
          expect(json_response["results"].length).to eq(30)
          expect(json_response["pagination"]["more"]).to be true
        end

        it "returns remaining results on subsequent pages with more flag as false" do
          get "/admin/reports/search_distributors", params: base_params.merge(page: 2)

          json_response = response.parsed_body
          expect(json_response["results"].length).to be > 0
          expect(json_response["pagination"]["more"]).to be false
        end
      end
    end
  end

  context "when user is not an admin" do
    before do
      login_as distributor1.users.first
      create_adjustment(orderA1, enterprise_fee1, 5.0)
      create_adjustment(orderA2, enterprise_fee2, 3.0)
    end

    describe "GET /admin/reports/search_enterprise_fees" do
      it "returns only enterprise fees for user's managed enterprises" do
        get "/admin/reports/search_enterprise_fees", params: base_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response["results"].pluck("label")).to eq(['Delivery Fee'])
        expect(json_response["pagination"]["more"]).to be false
      end
    end

    describe "GET /admin/reports/search_enterprise_fee_owners" do
      it "returns only enterprise fee owners for user's managed enterprises" do
        get "/admin/reports/search_enterprise_fee_owners", params: base_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response["results"].pluck("label")).to eq([distributor1.name])
        expect(json_response["pagination"]["more"]).to be false
      end
    end

    describe "GET /admin/reports/search_order_customers" do
      it "returns only customers from user's managed enterprises" do
        customer1 = create(:customer, email: "alice@example.com", enterprise: distributor1)
        customer2 = create(:customer, email: "bob@example.com", enterprise: distributor1)
        orderA1.update!(customer: customer1)
        orderA2.update!(customer: customer2)

        get "/admin/reports/search_order_customers", params: base_params

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(["alice@example.com"])
        expect(json_response["pagination"]["more"]).to be false
      end
    end

    describe "GET /admin/reports/search_order_cycles" do
      it "returns only order cycles accessible to user's managed enterprises" do
        ocA.update!(name: "Winter Market")
        ocB.update!(name: "Summer Market")
        create(:simple_order_cycle, name: 'Autumn Market', coordinator: coordinator1,
                                    distributors: [distributor2],
                                    suppliers: [supplier1, supplier2, supplier3],
                                    variants: [product2.variants.first])

        get "/admin/reports/search_order_cycles", params: base_params

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(["Summer Market", "Winter Market"])
        expect(json_response["pagination"]["more"]).to be false
      end
    end

    describe "GET /admin/reports/search_distributors" do
      it "returns only user's managed distributors" do
        get "/admin/reports/search_distributors", params: base_params

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq([distributor1.name])
        expect(json_response["pagination"]["more"]).to be false
      end
    end
  end
end
