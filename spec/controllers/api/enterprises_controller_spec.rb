require 'spec_helper'

module Api
  describe EnterprisesController, type: :controller do
    include AuthenticationWorkflow
    render_views

    let(:enterprise) { create(:distributor_enterprise) }

    before do
      stub_authentication!
      Enterprise.stub(:find).and_return(enterprise)
    end

    context "as an enterprise owner" do
      let(:enterprise_owner) { create_enterprise_user enterprise_limit: 10 }
      let(:enterprise) { create(:distributor_enterprise, owner: enterprise_owner) }

      before do
        Spree.user_class.stub :find_by_spree_api_key => enterprise_owner
      end

      describe "creating an enterprise" do
        let(:australia) { Spree::Country.find_by_name('Australia') }
        let(:new_enterprise_params) { {enterprise: {name: 'name', email: 'email@example.com', address_attributes: {address1: '123 Abc Street', city: 'Northcote', zipcode: '3070', state_id: australia.states.first, country_id: australia.id } } } }

        it "creates as sells=any when it is not a producer" do
          spree_post :create, new_enterprise_params
          response.should be_success

          enterprise = Enterprise.last
          enterprise.sells.should == 'any'
        end
      end
    end

    context "as an enterprise manager" do
      let(:enterprise_manager) { create_enterprise_user }

      before do
        enterprise_manager.enterprise_roles.build(enterprise: enterprise).save
        Spree.user_class.stub :find_by_spree_api_key => enterprise_manager
      end

      describe "submitting a valid image" do
        before do
          enterprise.stub(:update_attributes).and_return(true)
        end

        it "I can update enterprise image" do
          spree_post :update_image, logo: 'a logo'
          response.should be_success
        end
      end
    end

    describe "as an non-managing user" do
      let(:non_managing_user) { create_enterprise_user }

      before do
        Spree.user_class.stub :find_by_spree_api_key => non_managing_user
      end

      describe "submitting a valid image" do
        before do
          enterprise.stub(:update_attributes).and_return(true)
        end

        it "I can't update enterprise image" do
          spree_post :update_image, logo: 'a logo'
          assert_unauthorized!
        end
      end
    end
  end
end
