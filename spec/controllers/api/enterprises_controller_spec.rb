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
              name: 'name', contact_name: 'Sheila', address_attributes: {
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
          expect(response).to be_success

          enterprise = Enterprise.last
          expect(enterprise.sells).to eq('any')
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
          allow(enterprise).to receive(:update_attributes).and_return(true)
        end

        it "I can update enterprise image" do
          spree_post :update_image, logo: 'a logo', id: enterprise.id
          expect(response).to be_success
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
        before { allow(enterprise).to receive(:update_attributes).and_return(true) }

        it "I can't update enterprise image" do
          spree_post :update_image, logo: 'a logo', id: enterprise.id
          assert_unauthorized!
        end
      end
    end

    context "as a non-authenticated user" do
      let!(:hub) {
        create(:distributor_enterprise, with_payment_and_shipping: true, name: 'Shopfront Test Hub')
      }
      let!(:producer) { create(:supplier_enterprise, name: 'Shopfront Test Producer') }
      let!(:category) { create(:taxon, name: 'Fruit') }
      let!(:product) { create(:product, supplier: producer, primary_taxon: category ) }
      let!(:relationship) { create(:enterprise_relationship, parent: hub, child: producer) }

      before do
        allow(controller).to receive(:spree_current_user) { nil }
      end

      describe "fetching shopfronts data" do
        it "returns data for an enterprise" do
          spree_get :shopfront, id: producer.id, format: :json

          expect(json_response['name']).to eq 'Shopfront Test Producer'
          expect(json_response['hubs'][0]['name']).to eq 'Shopfront Test Hub'
          expect(json_response['supplied_taxons'][0]['name']).to eq 'Fruit'
        end
      end
    end
  end
end
