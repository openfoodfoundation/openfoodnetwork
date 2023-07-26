# frozen_string_literal: true

require "reflex_helper"

describe ProductsReflex, type: :reflex do
  let(:current_user) { create(:admin_user) } # todo: set up an enterprise user to test permissions
  let(:context) {
    { url: admin_products_v3_index_url, connection: { current_user: } }
  }

  before do
    # activate feature toggle admin_style_v3 to use new admin interface
    Flipper.enable(:admin_style_v3)
  end

  describe 'fetch' do
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
    let!(:product_b) { create(:simple_product, name: "Bananas") }
    let!(:product_a) { create(:simple_product, name: "Apples") }

    it "saves valid changes" do
      params = {
        # '[products][<i>][name]'
        "products" => [
          {
            "id" => product_a.id.to_s,
            "name" => "Pommes",
          }
        ]
      }

      expect{
        run_reflex(:bulk_update, params:)
        product_a.reload
      }.to change(product_a, :name).to("Pommes")
    end

    describe "sorting" do
      let(:params) {
        {
          "products" => [
            {
              "id" => product_a.id.to_s,
              "name" => "Pommes",
            },
            {
              "id" => product_b.id.to_s,
            },
          ]
        }
      }
      subject{ run_reflex(:bulk_update, params:) }

      it "Should retain sort order, even when names change" do
        expect(subject.get(:products).map(&:id)).to eq [
          product_a.id,
          product_b.id,
        ]
      end
    end

    describe "error messages" do
      it "summarises duplicate error messages" do
        params = {
          "products" => [
            {
              "id" => product_a.id.to_s,
              "name" => "",
            },
            {
              "id" => product_b.id.to_s,
              "name" => "",
            },
          ]
        }

        reflex = run_reflex(:bulk_update, params:)
        expect(reflex.get(:error_msg)).to eq "Product Name can't be blank"

        # # WTF
        # expect{ reflex(:bulk_update, params:) }.to broadcast(
        #   replace: {
        #     selector: "#products-form",
        #     html: /Product Name can't be blank/,
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
