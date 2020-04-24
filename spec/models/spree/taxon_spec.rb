require 'spec_helper'

module Spree
  describe Taxon do
    let(:e) { create(:supplier_enterprise) }
    let!(:t1) { create(:taxon) }
    let!(:t2) { create(:taxon) }

    describe "finding all supplied taxons" do
      let!(:p1) { create(:simple_product, supplier: e, taxons: [t1, t2]) }

      it "finds taxons" do
        expect(Taxon.supplied_taxons).to eq(e.id => Set.new(p1.taxons.map(&:id)))
      end
    end

    describe "finding distributed taxons" do
      let!(:oc_open)   { create(:open_order_cycle, distributors: [e], variants: [p_open.variants.first]) }
      let!(:oc_closed) { create(:closed_order_cycle, distributors: [e], variants: [p_closed.variants.first]) }
      let!(:p_open) { create(:simple_product, primary_taxon: t1) }
      let!(:p_closed) { create(:simple_product, primary_taxon: t2) }

      it "finds all distributed taxons" do
        expect(Taxon.distributed_taxons(:all)).to eq(e.id => Set.new([t1.id, t2.id]))
      end

      it "finds currently distributed taxons" do
        expect(Taxon.distributed_taxons(:current)).to eq(e.id => Set.new([t1.id]))
      end
    end

    describe "touches" do
      let!(:taxon1) { create(:taxon) }
      let!(:taxon2) { create(:taxon) }
      let!(:taxon3) { create(:taxon) }
      let!(:product) { create(:simple_product, primary_taxon: taxon1, taxons: [taxon1, taxon2]) }

      it "is touched when a taxon is applied to a product" do
        expect{ product.taxons << taxon3 }.to change { taxon3.reload.updated_at }
      end

      it "is touched when assignment of primary_taxon on a product changes" do
        expect do
          product.primary_taxon = taxon2
          product.save
        end.to change { taxon2.reload.updated_at }
      end
    end
  end
end
