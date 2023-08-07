# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe Taxon do
    let(:taxon) { Spree::Taxon.new(name: "Ruby on Rails") }

    let(:e) { create(:supplier_enterprise) }
    let(:t1) { create(:taxon) }
    let(:t2) { create(:taxon) }

    describe "finding all supplied taxons" do
      let!(:p1) { create(:simple_product, supplier: e, primary_taxon_id: t1.id) }

      it "finds taxons" do
        expect(Taxon.supplied_taxons).to eq(e.id => Set.new([t1.id]))
      end
    end

    describe "finding distributed taxons" do
      let!(:oc_open) {
        create(:open_order_cycle, distributors: [e], variants: [p_open.variants.first])
      }
      let!(:oc_closed) {
        create(:closed_order_cycle, distributors: [e], variants: [p_closed.variants.first])
      }
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
      let!(:product) { create(:simple_product, primary_taxon: taxon1) }

      it "is touched when assignment of primary_taxon on a product changes" do
        expect do
          product.primary_taxon = taxon2
          product.save
        end.to change { taxon2.reload.updated_at }
      end
    end

    context "set_permalink" do
      it "should set permalink correctly when no parent present" do
        taxon.set_permalink
        expect(taxon.permalink).to eq "ruby-on-rails"
      end

      it "should support Chinese characters" do
        taxon.name = "你好"
        taxon.set_permalink
        expect(taxon.permalink).to eq 'ni-hao'
      end

      context "with parent taxon" do
        before do
          allow(taxon).to receive_messages parent_id: 123
          allow(taxon).to receive_messages parent: build_stubbed(:taxon, permalink: "brands")
        end

        it "should set permalink correctly when taxon has parent" do
          taxon.set_permalink
          expect(taxon.permalink).to eq "brands/ruby-on-rails"
        end

        it "should set permalink correctly with existing permalink present" do
          taxon.permalink = "b/rubyonrails"
          taxon.set_permalink
          expect(taxon.permalink).to eq "brands/rubyonrails"
        end

        it "should support Chinese characters" do
          taxon.name = "我"
          taxon.set_permalink
          expect(taxon.permalink).to eq "brands/wo"
        end
      end
    end

    # Regression test for Spree #2620
    context "creating a child node using first_or_create" do
      let(:taxonomy) { create(:taxonomy) }

      it "does not error out" do
        expect {
          taxonomy.root.children.where(name: "Some name").first_or_create
        }.not_to raise_error
      end
    end
  end
end
