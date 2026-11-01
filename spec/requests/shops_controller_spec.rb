# frozen_string_literal: true

RSpec.describe "Shops" do
  let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let(:producer) { create(:supplier_enterprise) }
  let!(:taxon) {
    t = create(:taxon, name: "Fruit")
    t.update_column(:name_i18n, { "en" => "Fruit", "es" => "Fruta" })
    t
  }
  let!(:product) { create(:simple_product, enterprise_id: producer.id, primary_taxon: taxon) }
  let!(:order_cycle) {
    create(
      :simple_order_cycle,
      distributors: [distributor],
      coordinator: create(:distributor_enterprise),
      variants: [product.variants.first]
    )
  }

  describe "GET /shops" do
    it "injects taxon names in the current locale" do
      get shops_path(locale: "en")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('"name":"Fruit"')
    end

    it "injects taxon names in Spanish when the locale is es" do
      get shops_path(locale: "es")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('"name":"Fruta"')
    end
  end
end
