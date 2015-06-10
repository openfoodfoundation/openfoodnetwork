require 'spec_helper'

module Spree
  describe Taxon do
    let(:e) { create(:supplier_enterprise) }
    let(:t0) { p1.taxons.order('id ASC').first }
    let(:t1) { create(:taxon) }
    let(:t2) { create(:taxon) }

    describe "finding all supplied taxons" do
      let!(:p1) { create(:simple_product, supplier: e, taxons: [t1, t2]) }

      it "finds taxons" do
        Taxon.supplied_taxons.should == {e.id => Set.new([t0.id, t1.id, t2.id])}
      end
    end

    describe "finding all distributed taxons" do
      let!(:oc) { create(:simple_order_cycle, distributors: [e], variants: [p1.master]) }
      let(:s) { create(:supplier_enterprise) }
      let(:p1) { create(:simple_product, supplier: s, taxons: [t1, t2]) }

      it "finds taxons" do
        Taxon.distributed_taxons.should == {e.id => Set.new([t0.id, t1.id, t2.id])}
      end
    end
  end
end
