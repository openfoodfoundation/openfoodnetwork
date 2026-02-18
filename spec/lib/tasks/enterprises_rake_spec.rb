# frozen_string_literal: true

RSpec.describe 'enterprises.rake' do
  describe ':remove_enterprise' do
    context 'when the enterprises exists' do
      it 'removes the enterprise' do
        enterprise = create(:enterprise)

        expect {
          invoke_task "ofn:remove_enterprise[#{enterprise.id}]"
        }.to change { Enterprise.count }.by(-1)
      end
    end
  end

  describe ':enterprises' do
    describe ':activate_connected_app_type' do
      it 'updates only disconnected enterprises' do
        # enterprise with affiliate sales data
        enterprise_asd = create(:enterprise)
        enterprise_asd.connected_apps.create type: 'ConnectedApps::AffiliateSalesData'
        # enterprise with different type
        enterprise_diff = create(:enterprise)
        enterprise_diff.connected_apps.create

        expect {
          invoke_task(
            "ofn:enterprises:activate_connected_app_type[affiliate_sales_data]"
          )
        }.to change { ConnectedApps::AffiliateSalesData.count }.by(1)

        expect(enterprise_asd.connected_apps.affiliate_sales_data.count).to eq 1
        expect(enterprise_diff.connected_apps.affiliate_sales_data.count).to eq 1
      end
    end
  end
end
