# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe DfcProvider::SuppliedProductsController, type: :controller do
  include AuthorizationHelper

  render_views

  let!(:user) { create(:oidc_user) }
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
          allow_any_instance_of(AuthorizationControl)
            .to receive(:user)
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

  describe "#update" do
    routes { DfcProvider::Engine.routes }

    it "requires authorisation" do
      api_put :update, enterprise_id: "default", id: "0"
      expect(response).to have_http_status :unauthorized
    end

    describe "with authorisation" do
      before { authorise user.email }

      it "updates the variant's name" do
        params = { enterprise_id: enterprise.id, id: variant.id }
        request_body = File.read(File.join(__dir__, "../../support/patch_product.json"))

        expect {
          put(:update, params: params, body: request_body)
          expect(response).to have_http_status :success
          variant.reload
        }.to change {
          variant.name
        }
      end
    end
  end
end
