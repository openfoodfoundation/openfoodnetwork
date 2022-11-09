# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe DfcProvider::CatalogItemsController, type: :controller do
  include AuthorizationHelper

  render_views

  let!(:user) { create(:user) }
  let!(:enterprise) { create(:distributor_enterprise, owner: user) }
  let!(:product) { create(:simple_product, supplier: enterprise ) }
  let!(:variant) { product.variants.first }

  describe '.index' do
    context 'with authorization token' do
      before { authorise user.email }

      context 'with an authenticated user' do
        context 'with an enterprise' do
          context 'given with an id' do
            context 'related to the user' do
              before { api_get :index, enterprise_id: 'default' }

              it 'is successful' do
                expect(response).to have_http_status :success
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
                expect(response).to have_http_status :not_found
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
            expect(response).to have_http_status :not_found
          end
        end
      end

      context 'without an authenticated user' do
        before { authorise "other@user.net" }

        it 'returns unauthorized head' do
          authorise "other@user.net"

          api_get :index, enterprise_id: 'default'
          expect(response.response_code).to eq(401)
        end
      end
    end

    context 'without an authorization token' do
      it 'returns unauthorized head' do
        api_get :index, enterprise_id: enterprise.id
        expect(response).to have_http_status :unauthorized
      end
    end

    context "when logged in as app user" do
      it "is successful" do
        sign_in user
        api_get :index, enterprise_id: enterprise.id
        expect(response).to have_http_status :success
      end
    end
  end

  describe '.show' do
    context 'with authorization token' do
      before { authorise user.email }

      context 'with an authenticated user' do
        context 'with an enterprise' do
          context 'given with an id' do
            before do
              api_get :show, enterprise_id: enterprise.id, id: variant.id
            end

            it 'is successful' do
              expect(response).to have_http_status :success
            end

            it 'renders the required content' do
              expect(response.body).to include('dfc-b:CatalogItem')
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
              expect(response).to have_http_status :not_found
            end
          end
        end
      end
    end
  end
end
