# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "SuppliedProducts", swagger_doc: "dfc.yaml" do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) { create(:distributor_enterprise, id: 10_000, owner: user) }
  let!(:product) {
    create(
      :product_with_image,
      id: 90_000,
      name: "Pesto", description: "Basil Pesto",
      variants: [variant]
    )
  }
  let(:variant) {
    build(
      :base_variant,
      id: 10_001, sku: "BP", unit_value: 1,
      primary_taxon: taxon, supplier: enterprise,
    )
  }
  let(:taxon) {
    build(
      :taxon,
      name: "Processed Vegetable",
      dfc_id: "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#processed-vegetable"
    )
  }

  let!(:non_local_vegetable) {
    create(
      :taxon,
      name: "Non Local Vegetable",
      dfc_id: "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#non-local-vegetable"
    )
  }

  before { login_as user }

  path "/api/dfc/supplied_products" do
    get "Index SuppliedProducts" do
      produces "application/json"

      response "200", "success" do
        context "as platform user" do
          include_context "authenticated as platform"

          context "without permissions" do
            run_test! do
              expect(response.body).to eq ""
            end
          end

          context "with access to products" do
            before do
              DfcPermission.create!(
                user:, enterprise_id: 10_000,
                scope: "ReadEnterprise", grantee: "cqcm-dev",
              )
              DfcPermission.create!(
                user:, enterprise_id: 10_000,
                scope: "ReadProducts", grantee: "cqcm-dev",
              )
            end

            run_test! do
              expect(response.body).to include "Pesto"
            end
          end
        end

        context "as user owning two enterprises" do
          run_test! do
            expect(response.body).to include "Pesto"
          end
        end
      end
    end
  end

  path "/api/dfc/enterprises/{enterprise_id}/supplied_products" do
    parameter name: :enterprise_id, in: :path, type: :string

    let(:enterprise_id) { enterprise.id }

    post "Create SuppliedProduct" do
      consumes "application/json"
      produces "application/json"

      parameter name: :supplied_product, in: :body, schema: {
        example: {
          '@context': "https://www.datafoodconsortium.org",
          '@id': "http://test.host/api/dfc/enterprises/6201/supplied_products/0",
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

        it "creates a product and variant" do |example|
          # Despite requiring a tax catogory...
          # https://github.com/openfoodfoundation/openfoodnetwork/issues/11212
          create(:tax_category, is_default: true)
          Spree::Config.products_require_tax_category = true

          expect { submit_request(example.metadata) }
            .to change { enterprise.supplied_products.count }.by(1)

          dfc_id = json_response["@id"]
          expect(dfc_id).to match(
            %r|^http://test\.host/api/dfc/enterprises/10000/supplied_products/[0-9]+$|
          )

          spree_product_id = json_response["ofn:spree_product_id"].to_i

          variant_id = dfc_id.split("/").last.to_i
          variant = Spree::Variant.find(variant_id)
          expect(variant.name).to eq "Apple"
          expect(variant.unit_value).to eq 3
          expect(variant.product_id).to eq spree_product_id

          # References the associated Spree::Product
          product_id = json_response["ofn:spree_product_id"]
          product = Spree::Product.find(product_id)
          expect(product.name).to eq "Apple"
          expect(product.variants).to eq [variant]
          expect(product.variants.first.primary_taxon).to eq(non_local_vegetable)

          # Creates a variant for existing product
          supplied_product[:'ofn:spree_product_id'] = product_id
          supplied_product[:'dfc-b:hasQuantity'][:'dfc-b:value'] = 6

          expect {
            submit_request(example.metadata)
            product.variants.reload
          }
            .to change { product.variants.count }.by(1)

          variant_id = json_response["@id"].split("/").last.to_i
          second_variant = Spree::Variant.find(variant_id)
          expect(product.variants).to match_array [variant, second_variant]
          expect(second_variant.unit_value).to eq 6

          # Insert static value to keep documentation deterministic:
          supplied_product[:'ofn:spree_product_id'] = 90_000
          response.body.gsub!(
            "supplied_products/#{variant_id}",
            "supplied_products/10001"
          )
            .gsub!(
              "\"ofn:spree_product_id\":#{spree_product_id}",
              '"ofn:spree_product_id":90000'
            )
        end

        context "when supplying spree_product_uri matching the host" do
          it "creates a variant for the existing product" do |example|
            supplied_product[:'ofn:spree_product_uri'] =
              "http://test.host/api/dfc/enterprises/10000?spree_product_id=90000"
            supplied_product[:'dfc-b:hasQuantity'][:'dfc-b:value'] = 6

            expect {
              submit_request(example.metadata)
              product.variants.reload
            }
              .to change { product.variants.count }.by(1)

            # Creates a variant for existing product
            variant_id = json_response["@id"].split("/").last.to_i
            new_variant = Spree::Variant.find(variant_id)
            expect(product.variants).to include(new_variant)
            expect(new_variant.unit_value).to eq 6

            # Insert static value to keep documentation deterministic:
            response.body.gsub!(
              "supplied_products/#{variant_id}",
              "supplied_products/10001"
            )
          end
        end
      end
    end
  end

  path "/api/dfc/enterprises/{enterprise_id}/supplied_products/{id}" do
    parameter name: :enterprise_id, in: :path, type: :string
    parameter name: :id, in: :path, type: :string

    let(:enterprise_id) { enterprise.id }

    get "Show SuppliedProduct" do
      produces "application/json"

      response "200", "success" do
        let(:id) { variant.id }

        run_test! do
          expect(response.body).to include variant.name
          expect(json_response["dfc-b:isVariantOf"]).to eq "http://test.host/api/dfc/product_groups/90000"
          expect(json_response["ofn:spree_product_id"]).to eq 90_000
          expect(json_response["dfc-b:hasType"]).to eq("dfc-pt:processed-vegetable")
          expect(json_response["ofn:image"]).to include("logo-white.png")
        end
      end

      response "404", "not found" do
        let(:id) { other_variant.id }
        let(:other_variant) { create(:variant) }

        run_test!
      end
    end

    put "Update SuppliedProduct" do
      let!(:drink_taxon) {
        create(
          :taxon,
          name: "Drink",
          dfc_id: "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#drink"
        )
      }

      consumes "application/json"

      parameter name: :supplied_product, in: :body, schema: {
        example: ExampleJson.read("put_supplied_product")
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
            .and change { variant.display_name }.to("Pesto novo")
            .and change { variant.unit_value }.to(17)
            .and change { variant.primary_taxon }.to(drink_taxon)
        end
      end
    end
  end
end
