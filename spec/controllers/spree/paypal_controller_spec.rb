require 'spec_helper'

module Spree
  describe PaypalController do
    context 'when cancelling' do
      it 'redirects back to checkout' do
        expect(spree_get(:cancel)).to redirect_to checkout_path
      end
    end

    context 'when confirming' do
      let(:previous_order) { controller.current_order(true) }
      let(:payment_method) { create(:payment_method) }

      before do
        allow(previous_order).to receive(:complete?).and_return(true)
      end

      it 'resets the order' do
        spree_post :confirm, payment_method_id: payment_method.id
        expect(controller.current_order).not_to eq(previous_order)
      end

      it 'sets the access token of the session' do
        spree_post :confirm, payment_method_id: payment_method.id
        expect(session[:access_token]).to eq(controller.current_order.token)
      end
    end

    describe '#expire_current_order' do
      it 'empties the order_id of the session' do
        expect(session).to receive(:[]=).with(:order_id, nil)
        controller.expire_current_order
      end

      it 'resets the @current_order ivar' do
        controller.expire_current_order
        expect(controller.instance_variable_get(:@current_order)).to be_nil
      end
    end
  end
end
