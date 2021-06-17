# frozen_string_literal: true

require 'spec_helper'

describe DfcProvider::Api::SuppliedProductsController, type: :controller do
  render_views

  let!(:user) { create(:user) }
  let!(:enterprise) { create(:distributor_enterprise, owner: user) }
  let!(:product) { create(:simple_product, supplier: enterprise ) }
  let!(:variant) { product.variants.first }

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

        context 'with an enterprise' do
          context 'given with an id' do
            before do
              api_get :show, enterprise_id: 'default', id: variant.id
            end

            it 'is successful' do
              expect(response).to be_successful
            end

            it 'renders the required content' do
              expect(response.body).to include(variant.name)
            end
          end

          context 'given with a wrong id' do
            before { api_get :show, enterprise_id: 'default', id: 999 }

            it 'is not found' do
              expect(response).to be_not_found
            end
          end
        end
      end
    end
  end
end
