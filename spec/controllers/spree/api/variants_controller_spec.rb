require 'spec_helper'

module Spree
  describe Spree::Api::VariantsController, type: :controller do
    render_views

    let(:supplier) { FactoryGirl.create(:supplier_enterprise) }
    let!(:variant1) { FactoryGirl.create(:variant) }
    let!(:variant2) { FactoryGirl.create(:variant) }
    let!(:variant3) { FactoryGirl.create(:variant) }
    let(:attributes) { [:id, :options_text, :price, :on_hand, :unit_value, :unit_description, :on_demand, :display_as, :display_name] }

    before do
      stub_authentication!
      Spree.user_class.stub :find_by_spree_api_key => current_api_user
    end

    context "as a normal user" do
      sign_in_as_user!

      it "retrieves a list of variants with appropriate attributes" do
        spree_get :index, { :template => 'bulk_index', :format => :json }
        keys = json_response.first.keys.map{ |key| key.to_sym }
        attributes.all?{ |attr| keys.include? attr }.should == true
      end

      it "is denied access when trying to delete a variant" do
        product = create(:product)
        variant = product.master

        spree_delete :soft_delete, {variant_id: variant.to_param, product_id: product.to_param, format: :json}
        assert_unauthorized!
        lambda { variant.reload }.should_not raise_error
        variant.deleted_at.should be_nil
      end
    end

    context "as an enterprise user" do
      sign_in_as_enterprise_user! [:supplier]
      let(:supplier_other) { create(:supplier_enterprise) }
      let(:product) { create(:product, supplier: supplier) }
      let(:variant) { product.master }
      let(:product_other) { create(:product, supplier: supplier_other) }
      let(:variant_other) { product_other.master }

      it "soft deletes a variant" do
        spree_delete :soft_delete, {variant_id: variant.to_param, product_id: product.to_param, format: :json}
        response.status.should == 204
        lambda { variant.reload }.should_not raise_error
        variant.deleted_at.should be_present
      end

      it "is denied access to soft deleting another enterprises' variant" do
        spree_delete :soft_delete, {variant_id: variant_other.to_param, product_id: product_other.to_param, format: :json}
        assert_unauthorized!
        lambda { variant.reload }.should_not raise_error
        variant.deleted_at.should be_nil
      end
    end

    context "as an administrator" do
      sign_in_as_admin!

      it "soft deletes a variant" do
        product = create(:product)
        variant = product.master

        spree_delete :soft_delete, {variant_id: variant.to_param, product_id: product.to_param, format: :json}
        response.status.should == 204
        lambda { variant.reload }.should_not raise_error
        variant.deleted_at.should_not be_nil
      end
    end
  end
end
