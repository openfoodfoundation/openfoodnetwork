# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/swagger_helper")

describe "SuppliedProducts", type: :request, swagger_doc: "dfc-v1.7/swagger.yaml",
                             rswag_autodoc: true do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) { create(:distributor_enterprise, id: 10_000, owner: user) }
  let!(:product) {
    create(
      :base_product,
      supplier: enterprise, name: "Pesto", description: "Basil Pesto",
      variants: [variant],
    )
  }
  let(:variant) { build(:base_variant, id: 10_001, unit_value: 1) }

  before { login_as user }

  path "/api/dfc-v1.7/enterprises/{enterprise_id}/supplied_products" do
    parameter name: :enterprise_id, in: :path, type: :string

    let(:enterprise_id) { enterprise.id }

    post "Create SuppliedProduct" do
      consumes "application/json"
      produces "application/json"

      parameter name: :supplied_product, in: :body, schema: {
        example: {
          '@context': {
            'dfc-b': "http://static.datafoodconsortium.org/ontologies/DFC_BusinessOntology.owl#",
            'dfc-m': "http://static.datafoodconsortium.org/data/measures.rdf#",
            'dfc-pt': "http://static.datafoodconsortium.org/data/productTypes.rdf#",
          },
          '@id': "http://test.host/api/dfc-v1.7/enterprises/6201/supplied_products/0",
          '@type': "dfc-b:SuppliedProduct",
          'dfc-b:name': "Apple",
          'dfc-b:description': "A delicious heritage apple",
          'dfc-b:hasType': "dfc-pt:non-local-vegetable",
          'dfc-b:hasQuantity': {
            '@type': "dfc-b:QuantitativeValue",
            'dfc-b:hasUnit': "dfc-m:Gram",
            'dfc-b:value': 3.0
          },
          'dfc-b:alcoholPercentage': 0.0,
          'dfc-b:lifetime': "",
          'dfc-b:usageOrStorageCondition': "",
          'dfc-b:totalTheoreticalStock': 0.0
        }
      }

      response "400", "bad request" do
        describe "with missing request body" do
          around do |example|
            # Rswag expects all required parameters to be supplied with `let`
            # but we want to send a request without the request body parameter.
            parameters = example.metadata[:operation][:parameters]
            example.metadata[:operation][:parameters] = []
            example.run
            example.metadata[:operation][:parameters] = parameters
          end

          run_test!
        end

        describe "with empty request body" do
          let(:supplied_product) { nil }
          run_test!
        end
      end

      response "200", "success" do
        let(:supplied_product) do |example|
          example.metadata[:operation][:parameters].first[:schema][:example]
        end

        it "creates a variant" do |example|
          expect { submit_request(example.metadata) }
            .to change { enterprise.supplied_products.count }.by(1)

          dfc_id = json_response["@id"]
          expect(dfc_id).to match(
            %r|^http://test\.host/api/dfc-v1\.7/enterprises/10000/supplied_products/[0-9]+$|
          )

          variant_id = dfc_id.split("/").last.to_i
          variant = Spree::Variant.find(variant_id)
          expect(variant.name).to eq "Apple"
          expect(variant.unit_value).to eq 3

          # Insert static value to keep documentation deterministic:
          response.body.gsub!(
            "supplied_products/#{variant_id}",
            "supplied_products/10001"
          )
        end
      end
    end
  end

  path "/api/dfc-v1.7/enterprises/{enterprise_id}/supplied_products/{id}" do
    parameter name: :enterprise_id, in: :path, type: :string
    parameter name: :id, in: :path, type: :string

    let(:enterprise_id) { enterprise.id }

    get "Show SuppliedProduct" do
      produces "application/json"

      response "200", "success" do
        let(:id) { variant.id }

        run_test! do
          expect(response.body).to include variant.name
        end
      end

      response "404", "not found" do
        let(:id) { other_variant.id }
        let(:other_variant) { create(:variant) }

        run_test!
      end
    end

    put "Update SuppliedProduct" do
      consumes "application/json"

      parameter name: :supplied_product, in: :body, schema: {
        example: ExampleJson.read("patch_supplied_product")
      }

      let(:id) { variant.id }
      let(:supplied_product) { |example|
        example.metadata[:operation][:parameters].first[:schema][:example]
      }

      response "401", "unauthorized" do
        before { login_as nil }

        run_test!
      end

      response "204", "success" do
        it "updates a variant" do |example|
          expect {
            submit_request(example.metadata)
            variant.reload
          }.to change { variant.description }.to("DFC-Pesto updated")
            .and change { variant.unit_value }.to(17)
        end
      end
    end
  end
end
