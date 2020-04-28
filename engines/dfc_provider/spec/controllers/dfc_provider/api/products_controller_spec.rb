# frozen_string_literal: true

require 'spec_helper'

describe DfcProvider::Api::ProductsController, type: :controller do
  render_views

  let(:enterprise) { create(:distributor_enterprise) }
  let(:product) do
    create(:simple_product, supplier: enterprise )
  end
  let!(:visible_inventory_item) do
    create(:inventory_item,
           enterprise: enterprise,
           variant: product.variants.first,
           visible: true)
  end
  let(:user) { enterprise.owner }

  describe('.index') do
    context 'with authorization token' do
      before do
        request.env['Authorization'] = 'Bearer 123456.abcdef.123456'
      end

      context 'with an enterprise' do
        context 'with a linked user' do
          before do
            allow_any_instance_of(DfcProvider::AuthorizationControl)
              .to receive(:process)
              .and_return(user)
          end

          context 'with valid accessibility' do
            before do
              get :index, enterprise_id: enterprise.id
            end

            it 'is successful' do
              expect(response.status).to eq 200
            end

            it 'renders the related product' do
              expect(response.body)
                .to include("\"DFC:description\":\"#{product.variants.first.name}\"")
            end
          end

          context 'without valid accessibility' do
            before do
              get :index, enterprise_id: create(:enterprise).id
            end

            it 'returns unauthorized head' do
              expect(response.status).to eq 403
            end
          end
        end

        context 'without a linked user' do
          before do
            allow_any_instance_of(DfcProvider::AuthorizationControl)
              .to receive(:process)
              .and_return(nil)
          end

          before do
            get :index, enterprise_id: enterprise.id
          end

          it 'returns unprocessable_entity head' do
            expect(response.status).to eq 422
          end
        end
      end

      context 'without a recorded enterprise' do
        before do
          get :index, enterprise_id: '123456'
        end

        it 'returns not_found head' do
          expect(response.status).to eq 404
        end
      end
    end

    context 'without an authorization token' do
      before { get :index, enterprise_id: enterprise.id }

      it 'returns unauthorized head' do
        expect(response.status).to eq 401
      end
    end
  end
end
