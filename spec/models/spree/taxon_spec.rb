require 'spec_helper'

module Spree
  describe Taxon do
    let(:e) { create(:supplier_enterprise) }
    let!(:t1) { create(:taxon) }
    let!(:t2) { create(:taxon) }

    describe "callbacks" do
      let!(:p2) { create(:simple_product, taxons: [t1]) }

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

    describe "finding all distributed taxons" do
      let!(:oc) { create(:simple_order_cycle, distributors: [e], variants: [p1.master]) }
      let!(:s) { create(:supplier_enterprise) }
      let!(:p1) { create(:simple_product, supplier: s, taxons: [t1, t2]) }

      it "finds taxons" do
        Taxon.distributed_taxons.should == {e.id => Set.new(p1.taxons.map(&:id))}
      end
    end
  end
end
