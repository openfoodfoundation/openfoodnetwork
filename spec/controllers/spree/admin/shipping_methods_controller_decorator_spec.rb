require 'spec_helper'

describe Spree::Admin::ShippingMethodsController do
  include AuthenticationWorkflow

  describe '#destroy' do
    let!(:shipping_method) { create(:shipping_method) }

    before { login_as_admin }

    context 'when the shipping method is in use' do
      before { create(:order, shipping_method: shipping_method) }

      it 'does not allow to destroy the shipping method' do
        expect { delete :destroy, id: shipping_method.id }
          .not_to change(Spree::ShippingMethod, :count)
      end

      it 'shows a flash error message' do
        spree_delete :destroy, id: shipping_method.id
        expect(flash[:error]).to match('That shipping method cannot be deleted')
      end

      it 'redirects to the collection url' do
        expect(spree_delete(:destroy, id: shipping_method.id))
          .to redirect_to('/admin/shipping_methods')
      end
    end

    context 'when the shipping method is not in use' do
      it 'allows to destroy the shipping method' do
        expect { delete :destroy, id: shipping_method.id }
          .to change(Spree::ShippingMethod, :count)
      end
    end
  end
end
