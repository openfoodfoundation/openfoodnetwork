# frozen_string_literal: true

require "swagger_helper"

describe "Customers", type: :request do
  let!(:enterprise1) { create(:enterprise, name: "The Farm") }
  let!(:enterprise2) { create(:enterprise) }
  let!(:enterprise3) { create(:enterprise) }

  let!(:customer1) {
    create(
      :customer,
      enterprise: enterprise1,
      created_manually: true,
      terms_and_conditions_accepted_at: Time.zone.parse("2000-01-01"),
      tag_list: ["long-term"],
      ship_address: create(:address),
    )
  }
  let!(:customer2) { create(:customer, enterprise: enterprise1, created_manually: true,) }
  let!(:customer3) { create(:customer, enterprise: enterprise2, created_manually: true,) }

  before do
    Flipper.enable(:api_v1)
    login_as enterprise1.owner
  end

  path "/api/v1/customers" do
    get "List customers" do
      tags "Customers"
      parameter name: :enterprise_id, in: :query, type: :string
      parameter name: "extra_fields[customer]", in: :query, type: :string, example: :balance,
                description: "Add extra fields to each customer"
      produces "application/json"

      response "200", "Customers list" do
        param(:enterprise_id) { enterprise1.id }
        param("extra_fields[customer]") { :balance }
        schema "$ref": "#/components/schemas/customers_collection"

        run_test!
      end
    end

    describe "returning results based on permissions" do
      context "as guest user" do
        before { login_as nil }

        it "returns no customers" do
          get "/api/v1/customers"
          expect(json_response_ids).to eq []
        end

        it "returns not even customers without user id" do
          customer3.update!(user_id: nil)

          get "/api/v1/customers"
          expect(json_response_ids).to eq []
        end
      end

      context "as an enterprise owner" do
        before { login_as enterprise1.owner }

        it "returns customers of enterprises the user manages" do
          get "/api/v1/customers"
          expect(json_response_ids).to eq [customer1.id.to_s, customer2.id.to_s]
        end
      end

      context "as another enterprise owner" do
        before { login_as enterprise2.owner }

        it "returns customers of enterprises the user manages" do
          get "/api/v1/customers"
          expect(json_response_ids).to eq [customer3.id.to_s]
        end
      end

      context "as a user who manages the enterprise" do
        let!(:user){ enterprise3.users.first }
        before do
          EnterpriseRole.create!(user: user, enterprise: enterprise1)
          login_as user
        end

        it "returns customers of enterprises the user manages" do
          get "/api/v1/customers"
          expect(json_response_ids).to eq [customer1.id.to_s, customer2.id.to_s]
        end
      end

      context "as an enterprise that has edit profile permission" do
        let!(:user){ enterprise3.users.first }
        before do
          EnterpriseRelationship.create!(parent: enterprise1, child: enterprise3,
                                         permissions_list: [:edit_profile])
          login_as user
        end

        it "shoult not return customers of the managed enterprise" do
          get "/api/v1/customers"
          expect(json_response_ids).to eq []
        end
      end

      context "with ransack params searching for specific customers" do
        before { login_as enterprise2.owner }

        it "does not show results the user doesn't have permissions to view" do
          get "/api/v1/customers", params: { q: { id_eq: customer2.id } }

          expect(json_response_ids).to eq []
        end
      end
    end

    describe "pagination" do
      it "renders the first page" do
        get "/api/v1/customers", params: { page: "1" }
        expect(json_response_ids).to eq [customer1.id.to_s, customer2.id.to_s]
      end

      it "renders the second page" do
        get "/api/v1/customers", params: { page: "2", per_page: "1" }
        expect(json_response_ids).to eq [customer2.id.to_s]
      end

      it "renders beyond the available pages" do
        get "/api/v1/customers", params: { page: "2" }
        expect(json_response_ids).to eq []
      end

      it "informs about invalid pages" do
        get "/api/v1/customers", params: { page: "0" }
        expect(json_response_ids).to eq nil
        expect(json_error_detail).to eq 'expected :page >= 1; got "0"'
      end
    end

    describe "query parameters" do
      describe "extra_fields[customer]" do
        context "with balance" do
          it "adds balance to each customer" do
            get "/api/v1/customers", params: { extra_fields: { customer: :balance } }
            balances = json_response[:data].map{ |c| c[:attributes][:balance] }
            expect(balances.all?{ |b| b.is_a? Numeric }).to eq(true)
          end
        end

        context "with unknown field" do
          it "returns unprocessable entity" do
            get "/api/v1/customers", params: { extra_fields: { customer: :unknown } }
            expect([response.status, json_error_detail]).to eq [422, "Unsupported fields: unknown"]
          end
        end

        context "when not recevied" do
          it "does not add balances" do
            get "/api/v1/customers"
            balances = json_response[:data].map{ |c| c[:attributes][:balance] }
            expect([response.status, balances.compact]).to eq [200, []]
          end
        end
      end
    end

    post "Create customer" do
      tags "Customers"
      consumes "application/json"
      produces "application/json"

      parameter name: :customer, in: :body, schema: {
        type: :object,
        properties: CustomerSchema.writable_attributes,
        required: CustomerSchema.required_attributes
      }

      response "201", "Minimal customer created" do
        param(:customer) do
          {
            email: "test@example.com",
            enterprise_id: enterprise1.id.to_s
          }
        end
        schema "$ref": "#/components/schemas/customer"

        run_test! do
          expect(json_response[:data][:attributes]).to include(
            allow_charges: false,
            terms_and_conditions_accepted_at: nil,
          )
        end
      end

      response "201", "Example customer created" do
        param(:customer) do
          CustomerSchema.writable_attributes.transform_values do |attribute|
            attribute[:example]
          end.merge(
            enterprise_id: enterprise1.id,
          )
        end
        schema "$ref": "#/components/schemas/customer"

        run_test! do
          expect(json_response[:data][:attributes]).to include(
            first_name: "Alice",
            last_name: "Springs",
            code: "BUYER1",
            email: "alice@example.com",
            enterprise_id: enterprise1.id,
            tags: ["staff", "discount"],
            shipping_address: CustomerSchema.address_example
          )
        end
      end

      response "422", "Unpermitted parameter" do
        param(:customer) do
          {
            email: "test@example.com",
            enterprise_id: enterprise1.id.to_s,
            allow_charges: true,
          }
        end
        schema "$ref": "#/components/schemas/error_response"

        run_test! do
          expect(json_error_detail).to eq "Parameters not allowed in this request: allow_charges"
        end
      end

      response "422", "Unprocessable entity" do
        param(:customer) { {} }
        schema "$ref": "#/components/schemas/error_response"

        run_test! do
          expect(json_error_detail).to eq "A required parameter is missing or empty: customer"
          expect(json_response[:meta]).to eq nil
        end
      end
    end
  end

  path "/api/v1/customers/{id}" do
    get "Show customer" do
      tags "Customers"
      parameter name: :id, in: :path, type: :string
      produces "application/json"

      response "200", "Customer" do
        param(:id) { customer1.id }
        schema CustomerSchema.schema(
          require_all: true,
          extra_fields: { name: :balance, required: true }
        )

        run_test! do
          date_time_string =
            json_response[:data][:attributes][:terms_and_conditions_accepted_at]
          expect(date_time_string).to match /^2000-01-01T00:00:00.000[Z+-].*$/
          expect(DateTime.parse(date_time_string)).to eq(
            customer1.terms_and_conditions_accepted_at
          )
        end
      end

      response "404", "Not found" do
        param(:id) { 0 }
        schema "$ref": "#/components/schemas/error_response"

        run_test! do
          expect(json_error_detail).to eq "The resource you were looking for could not be found."
        end
      end

      context "without authentication" do
        before { logout }

        response "401", "Unauthorized" do
          param(:id) { customer1.id }
          schema "$ref": "#/components/schemas/error_response"

          run_test! do
            expect(json_error_detail).to eq "You are not authorized to perform that action."
          end
        end
      end

      describe "related records" do
        it "contains exactly the defined relationships" do
          get "/api/v1/customers/#{customer1.id}"

          relationships = json_response[:data][:relationships].keys
          expect(relationships).to match_array CustomerSchema.relationships.map(&:to_s)
        end

        it "serializes the enterprise relationship" do
          expected_enterprise_data = {
            "data" => {
              "id" => customer1.enterprise_id.to_s,
              "type" => "enterprise"
            },
            "links" => {
              "related" => "http://test.host/api/v1/enterprises/#{customer1.enterprise_id}"
            }
          }

          get "/api/v1/customers/#{customer1.id}"
          expect(json_response[:data][:relationships][:enterprise]).to eq(expected_enterprise_data)
        end
      end

      describe "including related records" do
        it "doesn't include other records by default" do
          get "/api/v1/customers/#{customer1.id}"

          expect(json_response[:included]).to eq nil
        end

        it "includes enterprise data on request" do
          get "/api/v1/customers/#{customer1.id}?include=enterprise"

          expect(json_response[:included].size).to eq 1
          expect(json_response[:included].first).to include(
            id: enterprise1.id.to_s,
            type: "enterprise",
            attributes: {
              id: enterprise1.id,
              name: "The Farm",
            }
          )
        end
      end
    end

    put "Update customer" do
      tags "Customers"
      parameter name: :id, in: :path, type: :string
      consumes "application/json"
      produces "application/json"

      parameter name: :customer, in: :body, schema: {
        type: :object,
        properties: CustomerSchema.writable_attributes,
        required: CustomerSchema.required_attributes
      }

      response "200", "Customer updated" do
        param(:id) { customer1.id }
        param(:customer) do
          {
            email: "test@example.com",
            enterprise_id: enterprise1.id.to_s
          }
        end
        schema "$ref": "#/components/schemas/customer"

        run_test! do
          # Tags should not be overridden when the param is missing:
          expect(json_response[:data][:attributes]).to include(
            tags: ["long-term"],
          )
        end
      end

      describe "address" do
        it "matches by country and state code" do
          put "/api/v1/customers/#{customer1.id}", params: {
            customer: {
              shipping_address: CustomerSchema.address_example.merge(
                region: { code: "Vic" },
                country: { code: "AU" },
              ),
            }
          }

          expect(response).to have_http_status :ok
          expect(json_response.dig(:data, :attributes, :shipping_address)).to include(
            region: { code: "Vic", name: "Victoria" },
            country: { code: "AU", name: "Australia" },
          )
        end

        it "matches by country and state name" do
          put "/api/v1/customers/#{customer1.id}", params: {
            customer: {
              shipping_address: CustomerSchema.address_example.merge(
                region: { name: "Victoria" },
                country: { name: "Australia" },
              ),
            }
          }

          expect(response).to have_http_status :ok
          expect(json_response.dig(:data, :attributes, :shipping_address)).to include(
            region: { code: "Vic", name: "Victoria" },
            country: { code: "AU", name: "Australia" },
          )
        end

        it "matches country and state case-insensitive" do
          put "/api/v1/customers/#{customer1.id}", params: {
            customer: {
              shipping_address: CustomerSchema.address_example.merge(
                region: { code: "VIC" },
                country: { name: "AUSTRALIA" },
              ),
            }
          }

          expect(response).to have_http_status :ok
          expect(json_response.dig(:data, :attributes, :shipping_address)).to include(
            region: { code: "Vic", name: "Victoria" },
            country: { code: "AU", name: "Australia" },
          )
        end
      end

      response "422", "Unprocessable entity" do
        param(:id) { customer1.id }
        param(:customer) { {} }
        schema "$ref": "#/components/schemas/error_response"

        run_test!
      end
    end

    delete "Delete customer" do
      tags "Customers"
      parameter name: :id, in: :path, type: :string
      produces "application/json"

      response "200", "Customer deleted" do
        param(:id) { customer1.id }
        schema "$ref": "#/components/schemas/customer"

        run_test!
      end
    end
  end

  path "/api/v1/enterprises/{enterprise_id}/customers" do
    get "List customers of an enterprise" do
      tags "Customers", "Enterprises"
      parameter name: :enterprise_id, in: :path, type: :string, required: true
      produces "application/json"

      response "200", "Customers list" do
        param(:enterprise_id) { enterprise1.id }
        schema "$ref": "#/components/schemas/customers_collection"

        run_test!
      end
    end
  end
end
