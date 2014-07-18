require 'spec_helper'

module Spree
  module Admin
    describe VariantsController do
      before { login_as_admin }

      describe "search action" do
        let!(:p1) { create(:simple_product, name: 'Product 1') }
        let!(:p2) { create(:simple_product, name: 'Product 2') }
        let!(:d)  { create(:distributor_enterprise) }
        let!(:oc) { create(:simple_order_cycle, distributors: [d], variants: [p1.master]) }

        it "filters by distributor" do
          spree_get :search, q: 'Prod', distributor_id: d.id.to_s
          assigns(:variants).should == [p1.master]
        end

        it "filters by order cycle" do
          spree_get :search, q: 'Prod', order_cycle_id: oc.id.to_s
          assigns(:variants).should == [p1.master]
        end

        it "does not filter when no distributor or order cycle is specified" do
          spree_get :search, q: 'Prod'
          assigns(:variants).sort.should == [p1.master, p2.master].sort
        end
      end
    end
  end
end
