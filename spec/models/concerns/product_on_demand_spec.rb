require 'spec_helper'

describe ProductOnDemand do
  describe '#on_demand=' do
    context 'when the product has no variants' do
      let(:product) { create(:simple_product) }

      before do
        product.variants.first.destroy
        product.variants.reload
      end

      it 'sets the value on master.on_demand' do
        product.on_demand = false
        expect(product.master.on_demand).to eq(false)
      end
    end

    context 'when the product has variants' do
      let(:product) { create(:simple_product) }

      it 'raises' do
        expect { product.on_demand = true }
          .to raise_error(StandardError, /cannot set on_demand/)
      end
    end
  end
end
