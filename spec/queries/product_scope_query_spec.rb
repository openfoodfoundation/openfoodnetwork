# frozen_string_literal: true

RSpec.describe ProductScopeQuery do
  let!(:taxon) { create(:taxon) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:supplier2) { create(:supplier_enterprise) }
  let!(:product) { create(:product, supplier_id: supplier.id, primary_taxon: taxon) }
  let!(:product2) { create(:product, supplier_id: supplier2.id, primary_taxon: taxon) }
  let!(:current_api_user) { supplier_enterprise_user(supplier) }

  before { current_api_user.enterprise_roles.create(enterprise: supplier2) }

  describe '#bulk_products' do
    let!(:product3) {
      create(:product, supplier_id: supplier2.id, primary_taxon_id: create(:taxon).id)
    }

    it "returns a list of products" do
      expect(ProductScopeQuery.new(current_api_user, {}).bulk_products)
        .to include(product, product2, product3)
    end

    it "filters results by supplier" do
      subject = ProductScopeQuery
        .new(current_api_user, { q: { variants_supplier_id_eq: supplier.id } }).bulk_products

      expect(subject).to include(product)
      expect(subject).not_to include(product2, product3)
    end

    describe "by variant category" do
      it "filters results by product category" do
        create(:variant, product: product2, primary_taxon: taxon)

        subject = ProductScopeQuery
          .new(current_api_user, { q: { variants_primary_taxon_id_eq: taxon.id } })
          .bulk_products

        expect(subject).to match_array([product, product2])
        expect(subject).not_to include(product3)
      end

      context "with mutiple variant in the same category" do
        it "doesn't duplicate products" do
          create(:variant, product: product2, primary_taxon: taxon)

          subject = ProductScopeQuery
            .new(current_api_user, { q: { variants_primary_taxon_id_eq: taxon.id } })
            .bulk_products

          expect(subject).to match_array([product, product2])
        end
      end
    end

    it "filters results by import_date" do
      product.variants.first.update_attribute :import_date, 1.day.ago
      product2.variants.first.update_attribute :import_date, 2.days.ago
      product3.variants.first.update_attribute :import_date, 1.day.ago

      subject = ProductScopeQuery
        .new(current_api_user, { import_date: 1.day.ago.to_date.to_s }).bulk_products

      expect(subject).to include(product, product3)
      expect(subject).not_to include(product2)
    end
  end

  describe 'finder functions' do
    describe 'find_product' do
      subject(:query) { ProductScopeQuery.new(current_api_user, { id: product.id }) }
      it 'finds product' do
        expect(query.find_product).to eq(product)
      end
    end

    describe 'find_product_to_be_cloned' do
      subject(:query) { ProductScopeQuery.new(current_api_user, { product_id: product2.id }) }
      it 'finds product to be cloned' do
        expect(query.find_product_to_be_cloned).to eq(product2)
      end
    end
  end

  describe "#products_for_producers" do
    subject(:query) { ProductScopeQuery.new(current_api_user, { page: 1, per_page: 20 }) }

    let(:hub) { create(:distributor_enterprise) }
    let(:producer_z) { create(:supplier_enterprise, name: "z_name") }
    let!(:product3) { create(:product, supplier_id: producer_z.id) }
    let!(:product4) { create(:product, supplier_id: producer_z.id) }
    let!(:product5) { create(:product, supplier_id: supplier.id) }
    let!(:er) {
      create(:enterprise_relationship, parent: producer_z, child: hub,
                                       permissions_list: [:create_variant_overrides])
    }

    before do
      current_api_user.enterprise_roles.create(enterprise: hub)
    end

    it "finds products by producer" do
      # Add variants so we can check if we are not returning duplicate products
      create(:variant, product: product3, supplier: producer_z)
      create(:variant, product: product3, supplier: producer_z)

      expect(query.products_for_producers).to eq([product3, product4])
    end

    it "order products by producer alphabetically and product alphabetically" do
      producer_b = create(:supplier_enterprise, name: "b_name")
      product_b1 = create(:product, name: "g_name", supplier_id: producer_b.id)
      product_b2 = create(:product, name: "z_name", supplier_id: producer_b.id)
      product_b3 = create(:product, name: "a_name", supplier_id: producer_b.id)

      create(:enterprise_relationship, parent: producer_b, child: hub,
                                       permissions_list: [:create_variant_overrides])

      result = query.products_for_producers
      expect(result).to eq([product_b3, product_b1, product_b2, product3, product4])
    end
  end

  private

  def supplier_enterprise_user(enterprise)
    user = create(:user)
    user.enterprise_roles.create(enterprise:)
    user
  end
end
