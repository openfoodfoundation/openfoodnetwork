describe SubscriptionEstimator do
  describe "#estimate!" do
    let!(:subscription) { create(:subscription, with_items: true) }
    let!(:sli1) { subscription.subscription_line_items.first }
    let!(:sli2) { subscription.subscription_line_items.second }
    let!(:sli3) { subscription.subscription_line_items.third }
    let(:fee_calculator) { nil }
    let(:estimator) { SubscriptionEstimator.new(subscription, fee_calculator) }

    before do
      sli1.update_attributes(price_estimate: 4.0)
      sli2.update_attributes(price_estimate: 5.0)
      sli3.update_attributes(price_estimate: 6.0)
      sli1.variant.update_attributes(price: 1.0)
      sli2.variant.update_attributes(price: 2.0)
      sli3.variant.update_attributes(price: 3.0)
    end

    context "when a fee calculator is not present" do
      it "removes price estimates from all items" do
        estimator.estimate!
        subscription.subscription_line_items.each do |item|
          expect(item.price_estimate).to eq 0
        end
      end
    end

    context "when a fee calculator is present" do
      let(:fee_calculator) { instance_double(OpenFoodNetwork::EnterpriseFeeCalculator) }

      before do
        allow(fee_calculator).to receive(:indexed_fees_for).with(sli1.variant) { 1.0 }
        allow(fee_calculator).to receive(:indexed_fees_for).with(sli2.variant) { 0.0 }
        allow(fee_calculator).to receive(:indexed_fees_for).with(sli3.variant) { 3.0 }
      end

      it "recalculates price_estimates based on variant prices and associated fees" do
        estimator.estimate!
        expect(sli1.price_estimate).to eq 2.0
        expect(sli2.price_estimate).to eq 2.0
        expect(sli3.price_estimate).to eq 6.0
      end
    end
  end
end
