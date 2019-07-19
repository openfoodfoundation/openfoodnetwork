require 'spec_helper'

module Spree
  describe Spree::Api::VariantsController, type: :controller do
    render_views

    let(:supplier) { FactoryBot.create(:supplier_enterprise) }
    let!(:variant1) { FactoryBot.create(:variant) }
    let!(:variant2) { FactoryBot.create(:variant) }
    let!(:variant3) { FactoryBot.create(:variant) }
    let(:attributes) { [:id, :options_text, :price, :on_hand, :unit_value, :unit_description, :on_demand, :display_as, :display_name] }

    before do
      allow(controller).to receive(:spree_current_user) { current_api_user }
    end

    context "as a normal user" do
      sign_in_as_user!

      it "retrieves a list of variants with appropriate attributes" do
        spree_get :index, template: 'bulk_index', format: :json
        keys = json_response.first.keys.map(&:to_sym)
        expect(attributes.all?{ |attr| keys.include? attr }).to eq(true)
      end

      it "is denied access when trying to delete a variant" do
        product = create(:product)
        variant = product.master

        spree_delete :soft_delete, variant_id: variant.to_param, product_id: product.to_param, format: :json
        assert_unauthorized!
        expect { variant.reload }.not_to raise_error
        expect(variant.deleted_at).to be_nil
      end

      let!(:product) { create(:product) }
      let!(:variant) do
        variant = product.master
        variant.option_values << create(:option_value)
        variant
      end
      let!(:attributes) { [:id, :name, :sku, :price, :weight, :height,
                           :width, :depth, :is_master, :cost_price,
                           :permalink] }

      it "can see a paginated list of variants" do
        api_get :index
        json_response["variants"].first.should have_attributes(attributes)
        json_response["count"].should == 1
        json_response["current_page"].should == 1
        json_response["pages"].should == 1
      end

      it 'can control the page size through a parameter' do
        create(:variant)
        api_get :index, :per_page => 1
        json_response['count'].should == 1
        json_response['current_page'].should == 1
        json_response['pages'].should == 3
      end

      it 'can query the results through a paramter' do
        expected_result = create(:variant, :sku => 'FOOBAR')
        api_get :index, :q => { :sku_cont => 'FOO' }
        json_response['count'].should == 1
        json_response['variants'].first['sku'].should eq expected_result.sku
      end

      it "variants returned contain option values data" do
        api_get :index
        option_values = json_response["variants"].last["option_values"]
        option_values.first.should have_attributes([:name,
                                                   :presentation,
                                                   :option_type_name,
                                                   :option_type_id])
      end

      it "variants returned contain images data" do
        variant.images.create!(:attachment => image("thinking-cat.jpg"))

        api_get :index

        json_response["variants"].last.should have_attributes([:images])
      end

      # Regression test for #2141
      context "a deleted variant" do
        before do
          variant.update_column(:deleted_at, Time.now)
        end

        it "is not returned in the results" do
          api_get :index
          json_response["variants"].count.should == 0
        end

        it "is not returned even when show_deleted is passed" do
          api_get :index, :show_deleted => true
          json_response["variants"].count.should == 0
        end
      end

      context "pagination" do
        it "can select the next page of variants" do
          second_variant = create(:variant)
          api_get :index, :page => 2, :per_page => 1
          json_response["variants"].first.should have_attributes(attributes)
          json_response["total_count"].should == 3
          json_response["current_page"].should == 2
          json_response["pages"].should == 3
        end
      end

      it "can see a single variant" do
        api_get :show, :id => variant.to_param
        json_response.should have_attributes(attributes)
        option_values = json_response["option_values"]
        option_values.first.should have_attributes([:name,
                                                   :presentation,
                                                   :option_type_name,
                                                   :option_type_id])
      end

      it "can see a single variant with images" do
        variant.images.create!(:attachment => image("thinking-cat.jpg"))

        api_get :show, :id => variant.to_param

        json_response.should have_attributes(attributes + [:images])
        option_values = json_response["option_values"]
        option_values.first.should have_attributes([:name,
                                                   :presentation,
                                                   :option_type_name,
                                                   :option_type_id])
      end

      it "can learn how to create a new variant" do
        api_get :new
        json_response["attributes"].should == attributes.map(&:to_s)
        json_response["required_attributes"].should be_empty
      end

      it "cannot create a new variant if not an admin" do
        api_post :create, :variant => { :sku => "12345" }
        assert_unauthorized!
      end

      it "cannot update a variant" do
        api_put :update, :id => variant.to_param, :variant => { :sku => "12345" }
        assert_unauthorized!
      end

      it "cannot delete a variant" do
        api_delete :destroy, :id => variant.to_param
        assert_unauthorized!
        lambda { variant.reload }.should_not raise_error
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
        spree_delete :soft_delete, variant_id: variant.to_param, product_id: product.to_param, format: :json
        expect(response.status).to eq(204)
        expect { variant.reload }.not_to raise_error
        expect(variant.deleted_at).to be_present
      end

      it "is denied access to soft deleting another enterprises' variant" do
        spree_delete :soft_delete, variant_id: variant_other.to_param, product_id: product_other.to_param, format: :json
        assert_unauthorized!
        expect { variant.reload }.not_to raise_error
        expect(variant.deleted_at).to be_nil
      end

      context 'when the variant is not the master' do
        before { variant.update_attribute(:is_master, false) }

        it 'refreshes the cache' do
          expect(OpenFoodNetwork::ProductsCache).to receive(:variant_destroyed).with(variant)
          spree_delete :soft_delete, variant_id: variant.id, product_id: variant.product.permalink, format: :json
        end
      end
    end

    context "as an administrator" do
      sign_in_as_admin!

      let(:product) { create(:product) }
      let(:variant) { product.master }
      let(:resource_scoping) { { :product_id => variant.product.to_param } }

      it "soft deletes a variant" do
        spree_delete :soft_delete, variant_id: variant.to_param, product_id: product.to_param, format: :json
        expect(response.status).to eq(204)
        expect { variant.reload }.not_to raise_error
        expect(variant.deleted_at).not_to be_nil
      end

      it "doesn't delete the only variant of the product" do
        product = create(:product)
        variant = product.variants.first

        spree_delete :soft_delete, variant_id: variant.to_param, product_id: product.to_param, format: :json

        expect(variant.reload).to_not be_deleted
        expect(assigns(:variant).errors[:product]).to include "must have at least one variant"
      end

      context 'when the variant is not the master' do
        before { variant.update_attribute(:is_master, false) }

        it 'refreshes the cache' do
          expect(OpenFoodNetwork::ProductsCache).to receive(:variant_destroyed).with(variant)
          spree_delete :soft_delete, variant_id: variant.id, product_id: variant.product.permalink, format: :json
        end
      end

      # Test for #2141
      context "deleted variants" do
        before do
          variant.update_column(:deleted_at, Time.now)
        end

        it "are visible by admin" do
          api_get :index, :show_deleted => 1
          json_response["variants"].count.should == 1
        end
      end

      it "can create a new variant" do
        api_post :create, :variant => { :sku => "12345" }
        json_response.should have_attributes(attributes)
        response.status.should == 201
        json_response["sku"].should == "12345"

        variant.product.variants.count.should == 1
      end

      it "can update a variant" do
        api_put :update, :id => variant.to_param, :variant => { :sku => "12345" }
        response.status.should == 200
      end

      it "can delete a variant" do
        api_delete :destroy, :id => variant.to_param
        response.status.should == 204
        lambda { Spree::Variant.find(variant.id) }.should raise_error(ActiveRecord::RecordNotFound)
      end      
    end
  end
end
