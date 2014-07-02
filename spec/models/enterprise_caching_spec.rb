require 'spec_helper'

describe Enterprise do
  context "key-based caching invalidation" do
    describe "is touched when a(n)" do
      let(:enterprise) { create(:distributor_enterprise, updated_at: 1.week.ago) }
      let(:taxon) { create(:taxon) }

      describe "with supplied taxon" do
        let(:product) { create(:simple_product, supplier: enterprise) }
        let!(:classification) { create(:classification, taxon: taxon, product: product) }
        it "supplied taxon is updated" do
          expect{classification.save!}.to change{enterprise.updated_at}
        end
      end

      describe "with distributed taxon" do
        let(:product) { create(:simple_product) }
        let!(:oc) { create(:simple_order_cycle, distributors: [enterprise], variants: [product.master]) }
        let!(:classification) { create(:classification, taxon: taxon, product: product) }
        it "distributed taxon is updated" do
          expect{classification.save!}.to change{enterprise.reload.updated_at}
        end
      end

      describe "with relatives" do
        let(:child_enterprise) { create(:supplier_enterprise) }
        let!(:er) { create(:enterprise_relationship, parent: enterprise, child: child_enterprise) }
        it "enterprise relationship is updated" do
          expect{er.save!}.to change {enterprise.reload.updated_at }  
        end
      end
      
      describe "with shipping methods" do
        let(:sm) { create(:shipping_method) }
        before do
          enterprise.shipping_methods << sm
        end
        it "distributor_shipping_method is updated" do
          expect {
            enterprise.distributor_shipping_methods.first.save!
          }.to change {enterprise.reload.updated_at}
        end

        it "shipping method is updated" do
          expect{sm.save!}.to change {enterprise.reload.updated_at }  
        end
      end
    end
  end
end
