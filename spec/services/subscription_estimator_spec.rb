describe SubscriptionEstimator do
  describe "#estimate!" do
    let!(:subscription) { create(:subscription, with_items: true) }
    let!(:sli1) { subscription.subscription_line_items.first }
    let!(:sli2) { subscription.subscription_line_items.second }
    let!(:sli3) { subscription.subscription_line_items.third }
    let(:estimator) { SubscriptionEstimator.new(subscription) }

    before do
      sli1.update_attributes(price_estimate: 4.0)
      sli2.update_attributes(price_estimate: 5.0)
      sli3.update_attributes(price_estimate: 6.0)
      sli1.variant.update_attributes(price: 1.0)
      sli2.variant.update_attributes(price: 2.0)
      sli3.variant.update_attributes(price: 3.0)

      # Simulating assignment of attrs from params
      sli1.assign_attributes(price_estimate: 7.0)
      sli2.assign_attributes(price_estimate: 8.0)
      sli3.assign_attributes(price_estimate: 9.0)
    end

    context "when a insufficient information exists to calculate price estimates" do
      before do
        # This might be because a shop has not been assigned yet, or no
        # current or future order cycles exist for the schedule
        allow(estimator).to receive(:fee_calculator) { nil }
      end

      it "resets the price estimates for all items" do
        estimator.estimate!
        expect(sli1.price_estimate).to eq 4.0
        expect(sli2.price_estimate).to eq 5.0
        expect(sli3.price_estimate).to eq 6.0
      end
    end

    context "when sufficient information to calculate price estimates exists" do
      let(:fee_calculator) { instance_double(OpenFoodNetwork::EnterpriseFeeCalculator) }

      before do
        allow(estimator).to receive(:fee_calculator) { fee_calculator }
        allow(fee_calculator).to receive(:indexed_fees_for).with(sli1.variant) { 1.0 }
        allow(fee_calculator).to receive(:indexed_fees_for).with(sli2.variant) { 0.0 }
        allow(fee_calculator).to receive(:indexed_fees_for).with(sli3.variant) { 3.0 }
      end

      context "when no variant overrides apply" do
        it "recalculates price_estimates based on variant prices and associated fees" do
          estimator.estimate!
          expect(sli1.price_estimate).to eq 2.0
          expect(sli2.price_estimate).to eq 2.0
          expect(sli3.price_estimate).to eq 6.0
        end
      end

      context "when variant overrides apply" do
        let!(:override1) { create(:variant_override, hub: subscription.shop, variant: sli1.variant, price: 1.2) }
        let!(:override2) { create(:variant_override, hub: subscription.shop, variant: sli2.variant, price: 2.3) }

        it "recalculates price_estimates based on override prices and associated fees" do
          estimator.estimate!
          expect(sli1.price_estimate).to eq 2.2
          expect(sli2.price_estimate).to eq 2.3
          expect(sli3.price_estimate).to eq 6.0
        end
      end
    end
  end
end
