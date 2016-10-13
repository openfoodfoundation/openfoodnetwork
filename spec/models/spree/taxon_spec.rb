require 'spec_helper'

module Spree
  describe Taxon do
    let(:e) { create(:supplier_enterprise) }
    let!(:t1) { create(:taxon) }
    let!(:t2) { create(:taxon) }

    describe "callbacks" do
      let!(:p2) { create(:simple_product, taxons: [t1], primary_taxon: t2) }

      it "refreshes the products cache on save" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(p2)
        t1.name = 'asdf'
        t1.save
      end

      it "refreshes the products cache on destroy" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(p2)
        t1.destroy
      end
    end

    describe "finding all supplied taxons" do
      let!(:p1) { create(:simple_product, supplier: e, taxons: [t1, t2]) }

      it "finds taxons" do
        Taxon.supplied_taxons.should == {e.id => Set.new(p1.taxons.map(&:id))}
      end
    end

    describe "finding distributed taxons" do
      let!(:oc_open)   { create(:open_order_cycle, distributors: [e], variants: [p_open.variants.first]) }
      let!(:oc_closed) { create(:closed_order_cycle, distributors: [e], variants: [p_closed.variants.first]) }
      let!(:p_open) { create(:simple_product, primary_taxon: t1) }
      let!(:p_closed) { create(:simple_product, primary_taxon: t2) }

      it "finds all distributed taxons" do
        expect(Taxon.distributed_taxons(:all)).to eq({e.id => Set.new([t1.id, t2.id])})
      end

      it "finds currently distributed taxons" do
        expect(Taxon.distributed_taxons(:current)).to eq({e.id => Set.new([t1.id])})
      end
    end
  end
end
