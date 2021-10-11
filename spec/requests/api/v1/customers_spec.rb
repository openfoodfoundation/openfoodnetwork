# frozen_string_literal: true

require "swagger_helper"

describe "Customers", type: :request do
  let!(:enterprise1) { create(:enterprise) }
  let!(:enterprise2) { create(:enterprise) }
  let!(:customer1) { create(:customer, enterprise: enterprise1) }
  let!(:customer2) { create(:customer, enterprise: enterprise1) }
  let!(:customer3) { create(:customer, enterprise: enterprise2) }

  before { login_as enterprise1.owner }

  path "/api/v1/customers" do
    get "List customers" do
      tags "Customers"
      parameter name: :enterprise_id, in: :query, type: :string
      produces "application/json"

      response "200", "Customers list" do
        param(:enterprise_id) { enterprise1.id }
        schema CustomerSchema.collection(require_all: true)

        run_test!
      end
    end

    describe "returning results based on permissions" do
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

      context "with ransack params searching for specific customers" do
        before { login_as enterprise2.owner }

        it "does not show results the user doesn't have permissions to view" do
          get "/api/v1/customers", params: { q: { id_eq: customer2.id } }

          expect(json_response_ids).to eq []
        end
      end
    end

    post "Create customer" do
      tags "Customers"
      consumes "application/json"
      produces "application/json"

      parameter name: :customer, in: :body, schema: {
        type: :object,
        properties: CustomerSchema.attributes.except(:id),
        required: CustomerSchema.required_attributes
      }

      response "201", "Customer created" do
        param(:customer) do
          {
            email: "test@example.com",
            enterprise_id: enterprise1.id.to_s
          }
        end
        schema CustomerSchema.schema(require_all: true)

        run_test!
      end

      response "422", "Unprocessable entity" do
        param(:customer) { {} }
        schema ErrorsSchema.schema

        run_test!
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
        schema CustomerSchema.schema(require_all: true)

        run_test!
      end

      response "404", "Not found" do
        param(:id) { 0 }
        schema ErrorsSchema.schema

        run_test! do
          expect(json_error_detail).to eq "The resource you were looking for could not be found."
        end
      end

      describe "related records" do
        it "serializes the enterprise relationship" do
          expected_enterprise_data = {
            "data" => {
              "id" => customer1.enterprise_id.to_s,
              "type" => "enterprise"
            }
          }

          get "/api/v1/customers/#{customer1.id}"
          expect(json_response[:data][:relationships][:enterprise]).to eq(expected_enterprise_data)
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
        properties: CustomerSchema.attributes,
        required: CustomerSchema.required_attributes
      }

      response "200", "Customer updated" do
        param(:id) { customer1.id }
        param(:customer) do
          {
            id: customer1.id.to_s,
            email: "test@example.com",
            enterprise_id: enterprise1.id.to_s
          }
        end
        schema CustomerSchema.schema(require_all: true)

        run_test!
      end

      response "422", "Unprocessable entity" do
        param(:id) { customer1.id }
        param(:customer) { {} }
        schema ErrorsSchema.schema

        run_test!
      end
    end

    delete "Delete customer" do
      tags "Customers"
      parameter name: :id, in: :path, type: :string
      produces "application/json"

      response "200", "Customer deleted" do
        param(:id) { customer1.id }
        schema CustomerSchema.schema(require_all: true)

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
        schema CustomerSchema.collection(require_all: true)

        run_test!
      end
    end
  end
end
