# frozen_string_literal: true

require 'spec_helper'

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
            expect(response).to be_successful
          end

          it 'renders the required content' do
            expect(response.body).to include('dfc:Person')
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
  end
end
