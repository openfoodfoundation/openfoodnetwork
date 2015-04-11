require 'spec_helper'

module Admin
  describe OrderCyclesController do
    include AuthenticationWorkflow

    let(:user) { create_enterprise_user }
    let(:admin_user) do
      user = create(:user)
      user.spree_roles << Spree::Role.find_or_create_by_name!('admin')
      user
    end
    let(:order_cycle) { create(:simple_order_cycle) }

    context 'order cycle has closed' do
      it 'can notify producers' do
        controller.stub spree_current_user: admin_user
        expect(Delayed::Job).to receive(:enqueue).once
        spree_post :notify_producers, {id: order_cycle.id}

        # TODO: is there a better variable to use?
        expect(response).to redirect_to spree.admin_path + '/order_cycles'
        flash[:notice].should == 'Emails to be sent to producers have been queued for sending.'
      end
    end
  end
end
