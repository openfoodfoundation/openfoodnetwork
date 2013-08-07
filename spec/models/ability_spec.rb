require 'spec_helper'
require "cancan/matchers"
require 'support/cancan_helper'

module Spree

  describe User do

    describe 'Roles' do

      # create enterprises
      let(:s1) { create(:supplier_enterprise) }
      let(:s2) { create(:supplier_enterprise) }
      let(:d1) { create(:distributor_enterprise) }
      let(:d2) { create(:distributor_enterprise) }
      # create product for each enterprise
      let(:p1) { create(:product, supplier: s1, distributors:[d1, d2]) }
      let(:p2) { create(:product, supplier: s2, distributors:[d1, d2]) }

      # create order for each enterprise
      let(:o1) do
        o = create(:order, distributor: d1, bill_address: create(:address))
        create(:line_item, order: o, product: p1)
        o
      end
      let(:o2) do
        o = create(:order, distributor: d2, bill_address: create(:address))
        create(:line_item, order: o, product: p1)
        o
      end

      subject { user }
      let(:user){ nil }

      context "when is a supplier enterprise user" do
        # create supplier_enterprise1 user without full admin access
        let (:user) do
          user = create(:user)
          user.spree_roles = []
          s1.enterprise_roles.build(user: user).save
          user
        end

        let (:order) {create(:order, )}

        it "should be able to read/write their enterprises' products" do
          should have_ability([:admin, :read, :update, :bulk_edit, :clone, :destroy], for: p1)
        end

        it "should not be able to read/write other enterprises' products" do
          should_not have_ability([:admin, :read, :update, :bulk_edit, :clone, :destroy], for: p2)
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
      end

      context "when is a distributor enterprise user" do
        # create distributor_enterprise1 user without full admin access
        let (:user) do
          user = create(:user)
          user.spree_roles = []
          d1.enterprise_roles.build(user: user).save
          user
        end

        it "should be able to read/write their enterprises' orders" do
          should have_ability([:admin, :index, :read, :edit], for: o1) 
        end

        it "should not be able to read/write other enterprises' orders" do
          should_not have_ability([:admin, :index, :read, :edit], for: o2) 
        end
      end

    end
  end
end