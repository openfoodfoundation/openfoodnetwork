require 'spec_helper'

module Api
  describe OrdersController, type: :controller do
    include AuthenticationWorkflow
    render_views

    describe '#index' do
      let!(:distributor) { create(:distributor_enterprise) }
      let!(:order1) { create(:order, distributor: distributor) }
      let!(:order2) { create(:order, distributor: distributor) }
      let!(:order3) { create(:order, distributor: distributor) }

      let(:enterprise_user) { distributor.owner }
      let(:regular_user) { create(:user) }

      context 'as a regular user' do
        before do
          allow(controller).to receive(:spree_current_user) { regular_user }
        end

        it "returns unauthorized" do
          get :index
          assert_unauthorized!
        end
      end

      context 'as an enterprise user' do
        before do
          allow(controller).to receive(:spree_current_user) { enterprise_user }
        end

        it "returns serialized orders" do
          get :index

          expect(response.status).to eq 200
          expect(json_response['orders'].count).to eq 3
          expect(json_response['orders'].first.keys).to include 'id', 'number', 'email', 'distributor'
          expect(json_response['pagination']).to be_nil
        end
      end

      context 'with pagination' do
        before do
          allow(controller).to receive(:spree_current_user) { enterprise_user }
        end

        it 'returns pagination data when query params contain :per_page]' do
          get :index, per_page: 15, page: 1

          expect(json_response['pagination']).to eq pagination_data
        end
      end
    end

    def pagination_data
      {
        'results' => 3,
        'pages' => 1,
        'page' => 1,
        'per_page' => 15
      }
    end
  end
end
