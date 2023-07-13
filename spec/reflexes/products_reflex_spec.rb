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
    let!(:product_z) { create(:simple_product, name: "Zucchini") }
    let!(:product_a) { create(:simple_product, name: "Apples") }

    it "saves valid changes" do
      params = {
        # '[products][<id>][name]'
        "products" => {
          product_a.id.to_s =>  {
            "name" => "Pommes",
          }
        }
      }

      expect{
        reflex(:bulk_update, params:)
        product_a.reload
      }.to change(product_a, :name).to("Pommes")
    end
  end
end

# Build and run a reflex using the context
# Parameters can be added with params: option
def reflex(method_name, opts = {})
  build_reflex(method_name:, **context.merge(opts)).run(method_name)
end
