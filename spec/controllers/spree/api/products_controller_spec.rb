require 'spec_helper'

module Spree
  describe Spree::Api::ProductsController, type: :controller do
    render_views

    let(:supplier) { create(:supplier_enterprise) }
    let(:supplier2) { create(:supplier_enterprise) }
    let!(:product) { create(:product, supplier: supplier) }
    let!(:inactive_product) { create(:product, :available_on => Time.now.tomorrow, :name => "inactive") }
    let(:product_other_supplier) { create(:product, supplier: supplier2) }
    let(:product_with_image) { create(:product_with_image, supplier: supplier) }
    let(:attributes) { ["id", "name", "supplier", "price", "on_hand", "available_on", "permalink_live"] }
    let(:all_attributes) { ["id", "name", "description", "price", "available_on", "permalink", "meta_description", "meta_keywords", "shipping_category_id", "taxon_ids", "variants", "option_types", "product_properties"] }

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

      it "retrieves a list of products" do
        api_get :index
        json_response["products"].first.should have_attributes({keys: all_attributes})


        json_response["count"].should == 1
        json_response["current_page"].should == 1
        json_response["pages"].should == 1
      end

      it "retrieves a list of products by id" do
        api_get :index, :ids => [product.id]
        json_response["products"].first.should have_attributes({keys: all_attributes})
        json_response["count"].should == 1
        json_response["current_page"].should == 1
        json_response["pages"].should == 1
      end

      it "does not return inactive products when queried by ids" do
        api_get :index, :ids => [inactive_product.id]
        json_response["count"].should == 0
      end

      it "does not list unavailable products" do
        api_get :index
        json_response["products"].first["name"].should_not eq("inactive")
      end

      context "pagination" do
        it "can select the next page of products" do
          second_product = create(:product)
          api_get :index, :page => 2, :per_page => 1
          json_response["products"].first.should have_attributes({keys: all_attributes})
          json_response["total_count"].should == 2
          json_response["current_page"].should == 2
          json_response["pages"].should == 2
        end

        it 'can control the page size through a parameter' do
          create(:product)
          api_get :index, :per_page => 1
          json_response['count'].should == 1
          json_response['total_count'].should == 2
          json_response['current_page'].should == 1
          json_response['pages'].should == 2
        end
      end

      context "jsonp" do
        it "retrieves a list of products of jsonp" do
          api_get :index, {:callback => 'callback'}
          response.body.should =~ /^callback\(.*\)$/
          response.header['Content-Type'].should include('application/javascript')
        end
      end

      it "can search for products" do
        create(:product, :name => "The best product in the world")
        api_get :index, :q => { :name_cont => "best" }
        json_response["products"].first.should have_attributes({keys: all_attributes})
        json_response["count"].should == 1
      end

      it "gets a single product" do
        product.master.images.create!(:attachment => image("thinking-cat.jpg"))
        product.variants.create!({ unit_value: "1", unit_description: "thing"})
        product.variants.first.images.create!(:attachment => image("thinking-cat.jpg"))
        product.set_property("spree", "rocks")
        api_get :show, :id => product.to_param
        json_response.should have_attributes({keys: all_attributes})
        json_response['variants'].first.should have_attributes({keys: ["id", "name", "sku", "price", "weight", "height", "width", "depth", "is_master", "cost_price", "permalink", "option_values", "images"]})
        json_response['variants'].first['images'].first.should have_attributes({keys: ["id", "position", "attachment_content_type", "attachment_file_name", "type", "attachment_updated_at", "attachment_width", "attachment_height", "alt", "viewable_type", "viewable_id", "attachment_url"]})
        json_response["product_properties"].first.should have_attributes({keys: ["id", "product_id", "property_id", "value", "property_name"]})
      end

      context "finds a product by permalink first then by id" do
        let!(:other_product) { create(:product, :permalink => "these-are-not-the-droids-you-are-looking-for") }

        before do
          product.update_attribute(:permalink, "#{other_product.id}-and-1-ways")
        end

        specify do
          api_get :show, :id => product.to_param
          json_response["permalink"].should =~ /and-1-ways/
          product.destroy

          api_get :show, :id => other_product.id
          json_response["permalink"].should =~ /droids/
        end
      end

      it "cannot see inactive products" do
        api_get :show, :id => inactive_product.to_param
        json_response["error"].should == "The resource you were looking for could not be found."
        response.status.should == 404
      end

      it "returns a 404 error when it cannot find a product" do
        api_get :show, :id => "non-existant"
        json_response["error"].should == "The resource you were looking for could not be found."
        response.status.should == 404
      end

      it "can learn how to create a new product" do
        api_get :new
        json_response["attributes"].should == ["id", "name", "description", "price", "available_on", "permalink", "meta_description", "meta_keywords", "shipping_category_id", "taxon_ids"]
        required_attributes = json_response["required_attributes"]
        required_attributes.should include("name")
        required_attributes.should include("price")
        required_attributes.should include("shipping_category_id")
      end

      include_examples "modifying product actions are restricted"
    end

    context "as an enterprise user" do
      let(:current_api_user) do
        user = create(:user)
        user.enterprise_roles.create(enterprise: supplier)
        user
      end

      it "retrieves a list of managed products" do
        spree_get :managed, template: 'bulk_index', format: :json
        response_keys = json_response.first.keys
        expect(attributes.all?{ |attr| response_keys.include? attr }).to eq(true)
      end

      it "soft deletes my products" do
        spree_delete :soft_delete, product_id: product.to_param, format: :json
        expect(response.status).to eq(204)
        expect { product.reload }.not_to raise_error
        expect(product.deleted_at).not_to be_nil
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
        response_keys = json_response.first.keys
        expect(attributes.all?{ |attr| response_keys.include? attr }).to eq(true)
      end

      it "retrieves a list of products with appropriate attributes" do
        spree_get :index, template: 'bulk_index', format: :json
        response_keys = json_response.first.keys
        expect(attributes.all?{ |attr| response_keys.include? attr }).to eq(true)
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
        expect(json_response.detect{ |product_in_response| product_in_response['id'] == product.id }['permalink_live']).to eq(product.permalink)
      end

      it "should allow available_on to be nil" do
        spree_get :index, template: 'bulk_index', format: :json
        expect(json_response.size).to eq(2)

        another_product = FactoryBot.create(:product)
        another_product.available_on = nil
        another_product.save!

        spree_get :index, template: 'bulk_index', format: :json
        expect(json_response.size).to eq(3)
      end

      it "soft deletes a product" do
        spree_delete :soft_delete, product_id: product.to_param, format: :json
        expect(response.status).to eq(204)
        expect { product.reload }.not_to raise_error
        expect(product.deleted_at).not_to be_nil
      end

      it "can see all products" do
        api_get :index
        json_response["products"].count.should == 2
        json_response["count"].should == 2
        json_response["current_page"].should == 1
        json_response["pages"].should == 1
      end

      # Regression test for #1626
      context "deleted products" do
        before do
          create(:product, :deleted_at => 1.day.ago)
        end

        it "does not include deleted products" do
          api_get :index
          json_response["products"].count.should == 2
        end

        it "can include deleted products" do
          api_get :index, :show_deleted => 1
          json_response["products"].count.should == 3
        end
      end

      it "can create a new product" do
        api_post :create, :product => { :name => "The Other Product",
                                        :price => 19.99,
                                        :shipping_category_id => create(:shipping_category).id,
                                        :supplier_id => supplier.id,
                                        :primary_taxon_id => FactoryBot.create(:taxon).id,
                                        :variant_unit => "items",
                                        :variant_unit_name => "things",
                                        :unit_description => "things"
                                      }
        json_response.should have_attributes({keys: all_attributes})
        response.status.should == 201
      end

      it "cannot create a new product with invalid attributes" do
        api_post :create, :product => {}
        response.status.should == 422
        json_response["error"].should == "Invalid resource. Please fix errors and try again."
        errors = json_response["errors"]
        errors.keys.should =~ ["name", "price", "primary_taxon", "shipping_category_id", "supplier", "variant_unit"]
      end

      it "can update a product" do
        api_put :update, :id => product.to_param, :product => { :name => "New and Improved Product!" }
        response.status.should == 200
      end

      it "cannot update a product with an invalid attribute" do
        api_put :update, :id => product.to_param, :product => { :name => "" }
        response.status.should == 422
        json_response["error"].should == "Invalid resource. Please fix errors and try again."
        json_response["errors"]["name"].should == ["can't be blank"]
      end

      it "can delete a product" do
        product.deleted_at.should be_nil
        api_delete :destroy, :id => product.to_param
        response.status.should == 204
        product.reload.deleted_at.should_not be_nil
      end
    end

    describe '#clone' do
      context 'as a normal user' do
        before do
          allow(current_api_user)
            .to receive(:has_spree_role?).with("admin").and_return(false)
        end

        it 'denies access' do
          spree_post :clone, product_id: product.id, format: :json
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
          spree_post :clone, product_id: product.id, format: :json
          expect(response.status).to eq(201)
        end

        it 'clones the product' do
          spree_post :clone, product_id: product.id, format: :json
          expect(json_response['name']).to eq("COPY OF #{product.name}")
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
          spree_post :clone, product_id: product.id, format: :json
          expect(response.status).to eq(201)
        end

        it 'clones the product' do
          spree_post :clone, product_id: product.id, format: :json
          expect(json_response['name']).to eq("COPY OF #{product.name}")
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
