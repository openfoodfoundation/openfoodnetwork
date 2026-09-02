# frozen_string_literal: false

RSpec.describe Admin::EnterpriseFeesController do
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
      before do
        allow(controller).to receive_messages spree_current_user: super_admin
      end

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

  describe "#bulk_update" do
    let(:enterprise) { create(:distributor_enterprise_with_tax) }
    let!(:fee1) { create(:enterprise_fee, :flat_rate, enterprise:, amount: 5.0) }
    let!(:fee2) { create(:enterprise_fee, :per_item, enterprise:, amount: 10.00) }
    let!(:other_fee) {
      create(:enterprise_fee, :flat_rate, enterprise: create(:distributor_enterprise),
                                          amount: 20.00)
    }

    before do
      allow(controller).to receive_messages spree_current_user: enterprise.owner
    end

    it "updates the enterprise fees" do
      params = {
        enterprise_id: enterprise.id,
        sets_enterprise_fee_set: {
          collection_attributes: {
            '0': {
              id: fee1.id,
              enterprise_id: fee1.enterprise_id,
              fee_type: fee1.fee_type,
              name: "sales fee",
              tax_category_id: nil,
              inherits_tax_category: fee1.inherits_tax_category,
              calculator_type: "Calculator::FlatRate",
              calculator_attributes: { id: fee1.calculator.id, preferred_amount: 10.00 }
            }
          }
        }
      }
      expect { post(:bulk_update, params: ) }
        .to change { fee1.reload.name }.to("sales fee")
        .and change { fee1.calculator.preferred_amount }.to(10.00)

      expect(response).to redirect_to admin_enterprise_fees_path(enterprise_id: enterprise.id)
    end

    it "doesn't update fees from another enterprise" do
      params = {
        enterprise_id: enterprise.id,
        sets_enterprise_fee_set: {
          collection_attributes: {
            '0': {
              id: fee1.id,
              enterprise_id: fee1.enterprise_id,
              fee_type: fee1.fee_type,
              name: "sales fee",
              tax_category_id: nil,
              inherits_tax_category: fee1.inherits_tax_category,
              calculator_type: "Calculator::FlatRate",
              calculator_attributes: { id: fee1.calculator.id, preferred_amount: 10.00 }
            },
            '1': {
              id: other_fee.id,
              enterprise_id: other_fee.enterprise_id,
              fee_type: other_fee.fee_type,
              name: "non updatable fee",
              tax_category_id: nil,
              inherits_tax_category: other_fee.inherits_tax_category,
              calculator_type: "Calculator::FlatRate",
              calculator_attributes: { id: other_fee.calculator.id, preferred_amount: 10.00 }
            }
          }
        }
      }
      expect { post(:bulk_update, params: ) }.not_to change { other_fee.reload.name }

      # We can not use not_to {..}.and change {} matcher, so checking fee1 has been updated
      expect(fee1.reload.name).to eq("sales fee")

      expect(response).to redirect_to admin_enterprise_fees_path(enterprise_id: enterprise.id)
    end

    it "filters out fees we are not allowed to update" do
      params = {
        enterprise_id: enterprise.id,
        sets_enterprise_fee_set: {
          collection_attributes: {
            '0': {
              id: fee1.id,
              enterprise_id: fee1.enterprise_id,
              fee_type: fee1.fee_type,
              name: "sales fee",
              tax_category_id: nil,
              inherits_tax_category: fee1.inherits_tax_category,
              calculator_type: "Calculator::FlatRate",
              calculator_attributes: { id: fee1.calculator.id, preferred_amount: 10.00 }
            },
            '1': {
              id: other_fee.id,
              enterprise_id: other_fee.enterprise_id,
              fee_type: other_fee.fee_type,
              name: "non updatable fee",
              tax_category_id: nil,
              inherits_tax_category: other_fee.inherits_tax_category,
              calculator_type: "Calculator::FlatRate",
              calculator_attributes: { id: other_fee.calculator.id, preferred_amount: 10.00 }
            }
          }
        }
      }

      allowed_fees = ActionController::Parameters.new(
        {
          id: fee1.id,
          enterprise_id: fee1.enterprise_id,
          fee_type: fee1.fee_type,
          name: "sales fee",
          tax_category_id: nil,
          inherits_tax_category: fee1.inherits_tax_category,
          calculator_type: "Calculator::FlatRate",
          calculator_attributes: { id: fee1.calculator.id, preferred_amount: 10.00 }
        }
      ).permit!

      filtered_params = {
        collection_attributes: {
          "0" => allowed_fees
        }
      }
      expect(EnterpriseFeesBulkUpdate).to receive(:new).with(filtered_params,
                                                             anything).and_call_original

      post(:bulk_update, params: )
    end
  end
end
