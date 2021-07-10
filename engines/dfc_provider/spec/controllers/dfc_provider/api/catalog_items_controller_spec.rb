# frozen_string_literal: true

require 'spec_helper'

describe DfcProvider::Api::CatalogItemsController, type: :controller do
  render_views

  let!(:user) { create(:user) }
  let!(:enterprise) { create(:distributor_enterprise, owner: user) }
  let!(:product) { create(:simple_product, supplier: enterprise ) }
  let!(:variant) { product.variants.first }

  describe '.index' do
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
            context 'related to the user' do
              before { api_get :index, enterprise_id: 'default' }

              it 'is successful' do
                expect(response).to be_successful
              end

              it 'renders the required content' do
                expect(response.body)
                  .to include(variant.name)
                expect(response.body)
                  .to include(variant.sku)
                expect(response.body)
                  .to include("offers/#{variant.id}")
              end
            end

            context 'not related to the user' do
              let(:enterprise) { create(:enterprise) }

              it 'returns not_found head' do
                api_get :index, enterprise_id: enterprise.id
                expect(response).to be_not_found
              end
            end
          end

          context 'as default' do
            before { api_get :index, enterprise_id: 'default' }

            it 'is successful' do
              expect(response.status).to eq 200
            end

            it 'renders the required content' do
              expect(response.body)
                .to include(variant.name)
              expect(response.body)
                .to include(variant.sku)
              expect(response.body)
                .to include("offers/#{variant.id}")
            end
          end
        end

        context 'without a recorded enterprise' do
          let(:enterprise) { create(:enterprise) }

          it 'is not found' do
            api_get :index, enterprise_id: 'default'
            expect(response).to be_not_found
          end
        end
      end

      context 'without an authenticated user' do
        it 'returns unauthorized head' do
          allow_any_instance_of(DfcProvider::AuthorizationControl)
            .to receive(:process)
            .and_return(nil)

          api_get :index, enterprise_id: 'default'
          expect(response.response_code).to eq(401)
        end
      end
    end

    context 'without an authorization token' do
      it 'returns unprocessable_entity head' do
        api_get :index, enterprise_id: enterprise.id
        expect(response).to be_unprocessable
      end
    end
  end

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
              api_get :show, enterprise_id: enterprise.id, id: variant.id
            end

            it 'is successful' do
              expect(response).to be_successful
            end

            it 'renders the required content' do
              expect(response.body).to include('dfc:CatalogItem')
              expect(response.body).to include("offers/#{variant.id}")
            end
          end

          context 'with a variant not linked to the enterprise' do
            before do
              api_get :show,
                      enterprise_id: enterprise.id,
                      id: create(:simple_product).variants.first.id
            end

            it 'is not found' do
              expect(response).to be_not_found
            end
          end
        end
      end
    end
  end
end
