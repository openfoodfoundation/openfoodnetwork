# frozen_string_literal: true

require "reflex_helper"

describe ProductsReflex, type: :reflex, feature: :admin_style_v3 do
  let(:current_user) { create(:admin_user) } # todo: set up an enterprise user to test permissions
  let(:context) {
    { url: admin_products_url, connection: { current_user: } }
  }
  let(:flash) { {} }

  before do
    # Mock flash, because stimulus_reflex_testing doesn't support sessions
    allow_any_instance_of(described_class).to receive(:flash).and_return(flash)
  end

  describe '#fetch' do
    subject{ build_reflex(method_name: :fetch, **context) }

    describe "sorting" do
      let!(:product_z) { create(:simple_product, name: "Zucchini") }
      # let!(:product_b) { create(:simple_product, name: "bananas") } # Fails on macOS
      let!(:product_a) { create(:simple_product, name: "Apples") }

      it "Should sort products alphabetically by default" do
        subject.run(:fetch)

        expect(subject.get(:products).to_a).to eq [
          product_a,
          # product_b,
          product_z,
        ]
      end
    end
  end

  describe '#bulk_update' do
    let!(:variant_a1) {
      create(:variant, product: product_a, display_name: "Medium box", sku: "APL-01", price: 5.25,
                       on_hand: 5, on_demand: false)
    }
    let!(:product_c) { create(:simple_product, name: "Carrots", sku: "CAR-00") }
    let!(:product_b) { create(:simple_product, name: "Bananas", sku: "BAN-00") }
    let!(:product_a) { create(:simple_product, name: "Apples", sku: "APL-00") }

    it "saves valid changes" do
      params = {
        # '[products][0][name]'
        "products" => {
          "0" => {
            "id" => product_a.id.to_s,
            "name" => "Pommes",
            "sku" => "POM-00",
          },
        },
      }

      expect{
        run_reflex(:bulk_update, params:)
        product_a.reload
      }.to change{ product_a.name }.to("Pommes")
        .and change{ product_a.sku }.to("POM-00")

      expect(flash).to include success: "Changes saved"
    end

    it "saves valid changes to products and nested variants" do
      # Form field names:
      #   '[products][0][id]' (hidden field)
      #   '[products][0][name]'
      #   '[products][0][variants_attributes][0][id]' (hidden field)
      #   '[products][0][variants_attributes][0][display_name]'
      params = {
        "products" => {
          "0" => {
            "id" => product_a.id.to_s,
            "name" => "Pommes",
            "variants_attributes" => {
              "0" => {
                "id" => variant_a1.id.to_s,
                "display_name" => "Large box",
                "sku" => "POM-01",
                "price" => "10.25",
                "on_hand" => "6",
              },
            },
          },
        },
      }

      expect{
        run_reflex(:bulk_update, params:)
        product_a.reload
        variant_a1.reload
      }.to change{ product_a.name }.to("Pommes")
        .and change{ variant_a1.display_name }.to("Large box")
        .and change{ variant_a1.sku }.to("POM-01")
        .and change{ variant_a1.price }.to(10.25)
        .and change{ variant_a1.on_hand }.to(6)

      expect(flash).to include success: "Changes saved"
    end

    describe "sorting" do
      let(:params) {
        {
          "products" => {
            "0" => {
              "id" => product_a.id.to_s,
              "name" => "Pommes",
            },
            "1" => {
              "id" => product_b.id.to_s,
            },
          },
        }
      }
      subject{ run_reflex(:bulk_update, params:) }

      it "Should retain sort order, even when names change" do
        expect(subject.get(:products).map(&:id)).to eq [
          product_a.id,
          product_b.id,
        ]
        expect(flash).to include success: "Changes saved"
      end
    end

    describe "error messages" do
      it "summarises error messages" do
        params = {
          "products" => {
            "0" => {
              "id" => product_a.id.to_s,
              "name" => "Pommes",
            },
            "1" => {
              "id" => product_b.id.to_s,
              "name" => "", # Name can't be blank
            },
            "2" => {
              "id" => product_c.id.to_s,
              "name" => "", # Name can't be blank
            },
          },
        }

        reflex = run_reflex(:bulk_update, params:)
        expect(reflex.get(:error_counts)).to eq({ saved: 1, invalid: 2 })
        expect(flash).to_not include success: "Changes saved"

        # # WTF
        # expect{ reflex(:bulk_update, params:) }.to broadcast(
        #   replace: {
        #     selector: "#products-form",
        #     html: /2 products have errors/,
        #   },
        #   broadcast: nil
        # )
      end
    end
  end
end

# Build and run a reflex using the context
# Parameters can be added with params: option
# For more options see https://github.com/podia/stimulus_reflex_testing#usage
def run_reflex(method_name, opts = {})
  build_reflex(method_name:, **context.merge(opts)).tap{ |reflex|
    reflex.run(method_name)
  }
end
