# frozen_string_literal: false

RSpec.describe Admin::EnterpriseFeesController do
  before do
    allow(controller).to receive_messages spree_current_user: super_admin
  end

  describe "for_order_cycle" do
    context "as super admin" do
      let(:super_admin) { create(:admin_user) }
      let!(:enterprise){ create(:distributor_enterprise_with_tax, name: 'Enterprise') }
      let!(:fee1) { create(:enterprise_fee, :flat_rate, enterprise:) }
      let!(:fee2) { create(:enterprise_fee, :per_item, enterprise:) }
      let!(:fee3) { create(:enterprise_fee, :flat_rate, enterprise:) }
      let!(:fee4) { create(:enterprise_fee, :per_item, enterprise:) }
      let!(:order_cycle){
        create(:simple_order_cycle, name: "oc1", suppliers: [enterprise],
                                    distributors: [enterprise])
      }

      it 'returns only per item enterprise fees of enterprise' do
        get :for_order_cycle, format: :json,
                              params: { for_order_cycle: true, order_cycle_id: order_cycle.id,
                                        per_item: true }
        expect(assigns(:collection)).to include fee2, fee4
      end
      it 'returns only per order enterprise fees of enterprise' do
        get :for_order_cycle, format: :json,
                              params: { for_order_cycle: true, order_cycle_id: order_cycle.id,
                                        per_order: true }
        expect(assigns(:collection)).to include fee1, fee3
      end
      it 'returns all enterprise fees of enterprise' do
        get :for_order_cycle, format: :json,
                              params: { for_order_cycle: true, order_cycle_id: order_cycle.id }
        expect(assigns(:collection)).to include fee1, fee2, fee3, fee4
      end
    end
  end
end
