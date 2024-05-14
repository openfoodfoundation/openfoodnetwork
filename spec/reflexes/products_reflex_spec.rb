# frozen_string_literal: true

require "reflex_helper"

RSpec.describe ProductsReflex, type: :reflex, feature: :admin_style_v3 do
  let(:current_user) { create(:admin_user) } # todo: set up an enterprise user to test permissions
  let(:context) {
    { url: admin_products_url, connection: { current_user: } }
  }
  let(:flash) { {} }

  before do
    # Mock flash, because stimulus_reflex_testing doesn't support sessions
    allow_any_instance_of(described_class).to receive(:flash).and_return(flash)
  end

  describe '#delete_product' do
    let(:product) { create(:simple_product) }
    let(:action_name) { :delete_product }

    subject { build_reflex(method_name: action_name, **context) }

    before { subject.element.dataset.current_id = product.id }

    context 'given that the current user is admin' do
      let(:current_user) { create(:admin_user) }

      it 'should successfully delete the product' do
        subject.run(action_name)
        product.reload
        expect(product.deleted_at).not_to be_nil
        expect(flash[:success]).to eq('Successfully deleted the product')
      end

      it 'should be failed to delete the product' do
        # mock db query failure
        allow_any_instance_of(Spree::Product).to receive(:destroy).and_return(false)
        subject.run(action_name)
        product.reload
        expect(product.deleted_at).to be_nil
        expect(flash[:error]).to eq('Unable to delete the product')
      end
    end

    context 'given that the current user is not admin' do
      let(:current_user) { create(:user) }

      it 'should raise the access denied exception' do
        expect { subject.run(action_name) }.to raise_exception(CanCan::AccessDenied)
      end
    end
  end

  describe '#delete_variant' do
    let(:variant) { create(:variant) }
    let(:action_name) { :delete_variant }

    subject { build_reflex(method_name: action_name, **context) }

    before { subject.element.dataset.current_id = variant.id }

    context 'given that the current user is admin' do
      let(:current_user) { create(:admin_user) }

      it 'should successfully delete the variant' do
        subject.run(action_name)
        variant.reload
        expect(variant.deleted_at).not_to be_nil
        expect(flash[:success]).to eq('Successfully deleted the variant')
      end

      it 'should be failed to delete the product' do
        # mock db query failure
        allow_any_instance_of(Spree::Variant).to receive(:destroy).and_return(false)
        subject.run(action_name)
        variant.reload
        expect(variant.deleted_at).to be_nil
        expect(flash[:error]).to eq('Unable to delete the variant')
      end
    end

    context 'given that the current user is not admin' do
      let(:current_user) { create(:user) }

      it 'should raise the access denied exception' do
        expect { subject.run(action_name) }.to raise_exception(CanCan::AccessDenied)
      end
    end
  end
end

# Build and run a reflex using the context
# Parameters can be added with params: option
# For more options see https://github.com/podia/stimulus_reflex_testing#usage
def run_reflex(method_name, opts = {})
  build_reflex(method_name:, **context.merge(opts)).tap{ |reflex|
    reflex.run(method_name)
  }
end
