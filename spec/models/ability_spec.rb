require 'spec_helper'
require "cancan/matchers"
require 'support/cancan_helper'

module Spree

  describe User do

    describe 'Roles' do

      # create enterprises
      let(:e1) { create(:enterprise) }
      let(:e2) { create(:enterprise) }
      let(:d1) { create(:distributor_enterprise) }
      # create product for each enterprise
      let(:p1) { create(:product, supplier: e1) }
      let(:p2) { create(:product, supplier: e2) }

      # create order
      # let(:order) { create(:order, distributor: d1, bill_address: create(:address)) }

      subject { user }
      let(:user){ nil }

      context "when is an enterprise user" do
        # create enterprise user without full admin access
        let (:user) do
          user = create(:user)
          user.spree_roles = []
          e1.enterprise_roles.build(user: user).save
          user
        end

        let (:order) {create(:order, )}

        it "should be able to read/write their enterprises' products" do
          should have_ability([:admin, :read, :update, :bulk_edit, :clone, :destroy], for: p1)
        end

        it "should be able to create a new product" do
          should have_ability(:create, for: Spree::Product)
        end

        it "should be able to read/write their enterprises' product variants" do 
          should have_ability([:admin, :index, :read, :create, :edit], for: Spree::Variant)
        end

        it "should be able to read/write their enterprises' product properties" do
          should have_ability([:admin, :index, :read, :create, :edit], for: Spree::ProductProperty)
        end

        it "should be able to read/write their enterprises' product images" do
          should have_ability([:admin, :index, :read, :create, :edit], for: Spree::Image)
        end
        
        it "should be able to read Taxons (in order to create classifications)" do
          should have_ability([:admin, :index, :read, :search], for: Spree::Taxon)
        end

        it "should be able to read/write Classifications on a product" do
          should have_ability([:admin, :index, :read, :create, :edit], for: Spree::Classification)
        end

        #TODO: definitely should check this on enterprise_roles
        it "should be able to read their enterprises' orders" # do
        #   should have_ability([:admin, :index, :read], for: o1) 
        # end
        
      end
    end
  end
end