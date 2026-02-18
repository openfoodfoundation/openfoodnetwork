# frozen_string_literal: true

RSpec.describe Spree::Taxon do
  let(:taxon) { described_class.new(name: "Ruby on Rails") }

  let(:e) { create(:supplier_enterprise) }
  let(:e2) { create(:supplier_enterprise) }
  let(:t1) { create(:taxon) }
  let(:t2) { create(:taxon) }

  describe ".supplied_taxons" do
    let!(:p1) {
      create(:simple_product, primary_taxon_id: t1.id, supplier_id: e.id)
    }
    let!(:p2) {
      create(:simple_product, primary_taxon_id: t2.id, supplier_id: e2.id)
    }

    context "when scoped to specific enterprises" do
      it "finds taxons" do
        expect(described_class.supplied_taxons([e.id])).to eq(e.id => Set.new([t1.id]))
        expect(described_class.supplied_taxons([e2.id])).to eq(e2.id => Set.new([t2.id]))
        expect(described_class.supplied_taxons([e.id, e2.id])).to eq(
          e.id => Set.new([t1.id]),
          e2.id => Set.new([t2.id])
        )
      end
    end

    context "when not scoped to specific enterprises" do
      it "finds taxons" do
        expect(described_class.supplied_taxons).to eq(
          e.id => Set.new([t1.id]),
          e2.id => Set.new([t2.id])
        )
      end
    end
  end

  describe ".distributed_taxons" do
    before do
      [e, e2].each do |ent|
        p_open = create(:simple_product, primary_taxon: t1)
        p_closed = create(:simple_product, primary_taxon: t2)
        create(:open_order_cycle, distributors: [ent], variants: [p_open.variants.first])
        create(:closed_order_cycle, distributors: [ent], variants: [p_closed.variants.first])
      end
    end

    context "when scoped to specific enterprises" do
      it "finds all distributed taxons" do
        expect(described_class.distributed_taxons(:all, [e.id])).to eq(
          e.id => Set.new([t1.id, t2.id])
        )
        expect(described_class.distributed_taxons(:all, [e2.id])).to eq(
          e2.id => Set.new([t1.id, t2.id])
        )
        expect(described_class.distributed_taxons(:all, [e.id, e2.id])).to eq(
          e.id => Set.new([t1.id, t2.id]),
          e2.id => Set.new([t1.id, t2.id]),
        )
      end

      it "finds currently distributed taxons" do
        expect(described_class.distributed_taxons(:current, [e.id])).to eq(
          e.id => Set.new([t1.id])
        )
        expect(described_class.distributed_taxons(:current, [e2.id])).to eq(
          e2.id => Set.new([t1.id])
        )
        expect(described_class.distributed_taxons(:current, [e.id, e2.id])).to eq(
          e.id => Set.new([t1.id]),
          e2.id => Set.new([t1.id]),
        )
      end
    end

    context "when not scoped to specific enterprises" do
      it "finds all distributed taxons" do
        expect(described_class.distributed_taxons(:all)).to eq(
          e.id => Set.new([t1.id, t2.id]),
          e2.id => Set.new([t1.id, t2.id]),
        )
      end

      it "finds currently distributed taxons" do
        expect(described_class.distributed_taxons(:current)).to eq(
          e.id => Set.new([t1.id]),
          e2.id => Set.new([t1.id]),
        )
      end
    end
  end

  describe "touches" do
    let!(:taxon1) { create(:taxon) }
    let!(:taxon2) { create(:taxon) }
    let!(:product) { create(:simple_product, primary_taxon_id: taxon1.id) }
    let(:variant) { product.variants.first }

    it "is touched when assignment of primary_taxon on a variant changes" do
      expect do
        variant.update(primary_taxon: taxon2)
      end.to change { taxon2.reload.updated_at }
    end
  end
end
