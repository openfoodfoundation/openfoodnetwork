# frozen_string_literal: true

require 'spec_helper'

describe DfcProvider::Api::ProductsController, type: :controller do
  render_views

  let(:user) { create(:user) }
  let(:enterprise) { create(:distributor_enterprise, owner: user) }
  let(:product) do
    create(:simple_product, supplier: enterprise )
  end
  let!(:visible_inventory_item) do
    create(:inventory_item,
           enterprise: enterprise,
           variant: product.variants.first,
           visible: true)
  end

  describe('.index') do
    context 'with authorization token' do
      before do
        request.env['Authorization'] = 'Bearer 123456.abcdef.123456'
      end

      context 'with an authenticated user' do
        before do
          allow_any_instance_of(DfcProvider::AuthorizationControl)
            .to receive(:process)
            .and_return(user)
        end

        context 'with an enterprise' do
          before { get :index }

          it 'is successful' do
            expect(response.status).to eq 200
          end

          it 'renders the related product' do
            expect(response.body)
              .to include("\"DFC:description\":\"#{product.variants.first.name}\"")
          end
        end

        context 'without a recorded enterprise' do
          let(:enterprise) { create(:enterprise) }

          before { get :index }

          it 'returns not_found head' do
            expect(response.status).to eq 404
          end
        end
      end

      context 'without an authenticated user' do
        before do
          allow_any_instance_of(DfcProvider::AuthorizationControl)
            .to receive(:process)
            .and_return(nil)
        end

        before { get :index }

        it 'returns unauthorized head' do
          expect(response.status).to eq 401
        end
      end
    end

    context 'without an authorization token' do
      before { get :index, enterprise_id: enterprise.id }

      it 'returns unprocessable_entity head' do
        expect(response.status).to eq 422
      end
    end
  end
end
