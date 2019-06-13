require 'spec_helper'

module Spree
  describe Spree::Api::ProductsController, type: :controller do
    render_views

    let(:supplier) { create(:supplier_enterprise) }
    let(:supplier2) { create(:supplier_enterprise) }
    let!(:product1) { create(:product, supplier: supplier) }
    let(:product_other_supplier) { create(:product, supplier: supplier2) }
    let(:product_with_image) { create(:product_with_image, supplier: supplier) }
    let(:attributes) { [:id, :name, :supplier, :price, :on_hand, :available_on, :permalink_live] }

    let(:current_api_user) { build(:user) }

    before do
      allow(controller).to receive(:spree_current_user) { current_api_user }
    end

    context "as a normal user" do
      before do
        allow(current_api_user)
          .to receive(:has_spree_role?).with("admin").and_return(false)
      end

      it "should deny me access to managed products" do
        spree_get :managed, template: 'bulk_index', format: :json
        assert_unauthorized!
      end
    end

    context "as an enterprise user" do
      let(:current_api_user) do
        user = create(:user)
        user.enterprise_roles.create(enterprise: supplier)
        user
      end

      it "retrieves a list of managed products" do
        spree_get :managed, template: 'bulk_index', format: :json
        keys = json_response.first.keys.map(&:to_sym)
        expect(attributes.all?{ |attr| keys.include? attr }).to eq(true)
      end

      it "soft deletes my products" do
        spree_delete :soft_delete, product_id: product1.to_param, format: :json
        expect(response.status).to eq(204)
        expect { product1.reload }.not_to raise_error
        expect(product1.deleted_at).not_to be_nil
      end

      it "is denied access to soft deleting another enterprises' product" do
        spree_delete :soft_delete, product_id: product_other_supplier.to_param, format: :json
        assert_unauthorized!
        expect { product_other_supplier.reload }.not_to raise_error
        expect(product_other_supplier.deleted_at).to be_nil
      end
    end

    context "as an administrator" do
      before do
        allow(current_api_user)
          .to receive(:has_spree_role?).with("admin").and_return(true)
      end

      it "retrieves a list of managed products" do
        spree_get :managed, template: 'bulk_index', format: :json
        keys = json_response.first.keys.map(&:to_sym)
        expect(attributes.all?{ |attr| keys.include? attr }).to eq(true)
      end

      it "retrieves a list of products with appropriate attributes" do
        spree_get :index, template: 'bulk_index', format: :json
        keys = json_response.first.keys.map(&:to_sym)
        expect(attributes.all?{ |attr| keys.include? attr }).to eq(true)
      end

      it "sorts products in ascending id order" do
        FactoryBot.create(:product, supplier: supplier)
        FactoryBot.create(:product, supplier: supplier)

        spree_get :index, template: 'bulk_index', format: :json

        ids = json_response.map{ |product| product['id'] }
        expect(ids[0]).to be < ids[1]
        expect(ids[1]).to be < ids[2]
      end

      it "formats available_on to 'yyyy-mm-dd hh:mm'" do
        spree_get :index, template: 'bulk_index', format: :json
        expect(json_response.map{ |product| product['available_on'] }.all?{ |a| a.match("^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$") }).to eq(true)
      end

      it "returns permalink as permalink_live" do
        spree_get :index, template: 'bulk_index', format: :json
        expect(json_response.detect{ |product| product['id'] == product1.id }['permalink_live']).to eq(product1.permalink)
      end

      it "should allow available_on to be nil" do
        spree_get :index, template: 'bulk_index', format: :json
        expect(json_response.size).to eq(1)

        product5 = FactoryBot.create(:product)
        product5.available_on = nil
        product5.save!

        spree_get :index, template: 'bulk_index', format: :json
        expect(json_response.size).to eq(2)
      end

      it "soft deletes a product" do
        spree_delete :soft_delete, product_id: product1.to_param, format: :json
        expect(response.status).to eq(204)
        expect { product1.reload }.not_to raise_error
        expect(product1.deleted_at).not_to be_nil
      end
    end

    describe '#clone' do
      context 'as a normal user' do
        before do
          allow(current_api_user)
            .to receive(:has_spree_role?).with("admin").and_return(false)
        end

        it 'denies access' do
          spree_post :clone, product_id: product1.id, format: :json
          assert_unauthorized!
        end
      end

      context 'as an enterprise user' do
        let(:current_api_user) do
          user = create(:user)
          user.enterprise_roles.create(enterprise: supplier)
          user
        end

        it 'responds with a successful response' do
          spree_post :clone, product_id: product1.id, format: :json
          expect(response.status).to eq(201)
        end

        it 'clones the product' do
          spree_post :clone, product_id: product1.id, format: :json
          expect(json_response['name']).to eq("COPY OF #{product1.name}")
        end

        it 'clones a product with image' do
          spree_post :clone, product_id: product_with_image.id, format: :json
          expect(response.status).to eq(201)
          expect(json_response['name']).to eq("COPY OF #{product_with_image.name}")
        end
      end

      context 'as an administrator' do
        before do
          allow(current_api_user)
            .to receive(:has_spree_role?).with("admin").and_return(true)
        end

        it 'responds with a successful response' do
          spree_post :clone, product_id: product1.id, format: :json
          expect(response.status).to eq(201)
        end

        it 'clones the product' do
          spree_post :clone, product_id: product1.id, format: :json
          expect(json_response['name']).to eq("COPY OF #{product1.name}")
        end

        it 'clones a product with image' do
          spree_post :clone, product_id: product_with_image.id, format: :json
          expect(response.status).to eq(201)
          expect(json_response['name']).to eq("COPY OF #{product_with_image.name}")
        end
      end
    end
  end
end
