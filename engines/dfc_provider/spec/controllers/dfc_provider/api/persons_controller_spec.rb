# frozen_string_literal: true

require 'spec_helper.rb'
require Rails.root.join('engines/dfc_provider/spec/spec_helper.rb')

describe DfcProvider::Api::PersonsController, type: :controller do
  render_views

  let!(:user) { create(:user) }

  describe '.show' do
    context 'with authorization token' do
      before do
        request.headers['Authorization'] = 'Bearer 123456.abcdef.123456'
      end

      context 'with an authenticated user' do
        before do
          allow_any_instance_of(DfcProvider::AuthorizationControl)
            .to receive(:process)
            .and_return(user)
        end

        context 'given with an accessible id' do
          before { api_get :show, id: user.id }

          it 'is successful' do
            expect(response).to be_success
          end

          it 'renders the required content' do
            expect(response.body).to include('dfc-b:Person')
          end
        end

        context 'with an other user id' do
          before { api_get :show, id: create(:user).id }

          it 'is not found' do
            expect(response).to be_not_found
          end
        end
      end
    end

    context 'when the feature is not activated' do
      before do
        Spree::Config[:enable_dfc_api?] = false
        api_get :show, id: create(:user).id
      end

      it 'returns a forbidden response' do
        expect(response).to be_forbidden
      end
    end
  end
end
