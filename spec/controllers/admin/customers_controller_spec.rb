describe Admin::CustomersController, type: :controller do
  include AuthenticationWorkflow

  describe "index" do
    let(:enterprise) { create(:distributor_enterprise) }
    let(:another_enterprise) { create(:distributor_enterprise) }

    context "html" do
      before do
        controller.stub spree_current_user: enterprise.owner
      end

      it "returns an empty @collection" do
        spree_get :index, format: :html
        expect(assigns(:collection)).to eq []
      end
    end

    context "json" do
      let!(:customer) { create(:customer, enterprise: enterprise) }

      context "where I manage the enterprise" do
        before do
          controller.stub spree_current_user: enterprise.owner
        end

        context "and enterprise_id is given in params" do
          let(:params) { { format: :json, enterprise_id: enterprise.id } }

          it "scopes @collection to customers of that enterprise" do
            spree_get :index, params
            expect(assigns(:collection)).to eq [customer]
          end

          it "serializes the data" do
            expect(ActiveModel::ArraySerializer).to receive(:new)
            spree_get :index, params
          end
        end

        context "and enterprise_id is not given in params" do
          it "returns an empty collection" do
            spree_get :index, format: :json
            expect(assigns(:collection)).to eq []
          end
        end
      end

      context "and I do not manage the enterprise" do
        before do
          controller.stub spree_current_user: another_enterprise.owner
        end

        it "returns an empty collection" do
          spree_get :index, format: :json
          expect(assigns(:collection)).to eq []
        end
      end
    end

  end
end
