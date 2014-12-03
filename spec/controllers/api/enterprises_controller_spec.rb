require 'spec_helper'

module Api
  describe EnterprisesController do
    include AuthenticationWorkflow
    render_views

    let(:enterprise) { create(:distributor_enterprise) }

    before do
      stub_authentication!
      Enterprise.stub(:find).and_return(enterprise)
    end

    describe "as an enterprise manager" do
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
