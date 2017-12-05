require 'spec_helper'

module Api
  describe EnterprisesController, type: :controller do
    include AuthenticationWorkflow
    render_views

    let(:enterprise) { create(:distributor_enterprise) }

    context "as an enterprise owner" do
      let(:enterprise_owner) { create_enterprise_user enterprise_limit: 10 }
      let!(:enterprise) { create(:distributor_enterprise, owner: enterprise_owner) }

      before do
        allow(controller).to receive(:spree_current_user) { enterprise_owner }
      end

      describe "creating an enterprise" do
        let(:australia) { Spree::Country.find_by_name('Australia') }
        let(:new_enterprise_params) do
          {
            enterprise: {
              name: 'name', email: 'email@example.com', address_attributes: {
                address1: '123 Abc Street',
                city: 'Northcote',
                zipcode: '3070',
                state_id: australia.states.first,
                country_id: australia.id
              }
            }
          }
        end

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
        allow(controller).to receive(:spree_current_user) { enterprise_manager }
      end

      describe "submitting a valid image" do
        before do
          allow(Enterprise)
            .to receive(:find_by_permalink).with(enterprise.id.to_s) { enterprise }
          enterprise.stub(:update_attributes).and_return(true)
        end

        it "I can update enterprise image" do
          spree_post :update_image, logo: 'a logo', id: enterprise.id
          response.should be_success
        end
      end
    end

    context "as an non-managing user" do
      let(:non_managing_user) { create_enterprise_user }

      before do
        allow(Enterprise)
          .to receive(:find_by_permalink).with(enterprise.id.to_s) { enterprise }
        allow(controller).to receive(:spree_current_user) { non_managing_user }
      end

      describe "submitting a valid image" do
        before { enterprise.stub(:update_attributes).and_return(true) }

        it "I can't update enterprise image" do
          spree_post :update_image, logo: 'a logo', id: enterprise.id
          assert_unauthorized!
        end
      end
    end
  end
end
