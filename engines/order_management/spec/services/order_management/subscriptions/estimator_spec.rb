# frozen_string_literal: true

require 'spec_helper'

module OrderManagement
  module Subscriptions
    describe Estimator do
      describe "estimating prices for subscription line items" do
        let!(:subscription) { create(:subscription, with_items: true) }
        let!(:sli1) { subscription.subscription_line_items.first }
        let!(:sli2) { subscription.subscription_line_items.second }
        let!(:sli3) { subscription.subscription_line_items.third }
        let(:estimator) { Estimator.new(subscription) }

        before do
          sli1.update(price_estimate: 4.0)
          sli2.update(price_estimate: 5.0)
          sli3.update(price_estimate: 6.0)
          sli1.variant.update(price: 1.0)
          sli2.variant.update(price: 2.0)
          sli3.variant.update(price: 3.0)

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
            let!(:override1) {
              create(:variant_override, hub: subscription.shop, variant: sli1.variant, price: 1.2)
            }
            let!(:override2) {
              create(:variant_override, hub: subscription.shop, variant: sli2.variant, price: 2.3)
            }

            it "recalculates price_estimates based on override prices and associated fees" do
              estimator.estimate!
              expect(sli1.price_estimate).to eq 2.2
              expect(sli2.price_estimate).to eq 2.3
              expect(sli3.price_estimate).to eq 6.0
            end
          end
        end
      end

      describe "updating estimates for shipping and payment fees" do
        let(:subscription) {
          create(:subscription, with_items: true,
                                payment_method: payment_method,
                                shipping_method: shipping_method)
        }
        let!(:sli1) { subscription.subscription_line_items.first }
        let!(:sli2) { subscription.subscription_line_items.second }
        let!(:sli3) { subscription.subscription_line_items.third }
        let(:estimator) { OrderManagement::Subscriptions::Estimator.new(subscription) }

        before do
          allow(estimator).to receive(:assign_price_estimates)
          sli1.update(price_estimate: 4.0)
          sli2.update(price_estimate: 5.0)
          sli3.update(price_estimate: 6.0)
        end

        context "using flat rate calculators" do
          let(:shipping_method) {
            create(:shipping_method,
                   calculator: Calculator::FlatRate.new(preferred_amount: 12.34))
          }
          let(:payment_method) {
            create(:payment_method,
                   calculator: Calculator::FlatRate.new(preferred_amount: 9.12))
          }

          it "calculates fees based on the rates provided" do
            estimator.estimate!
            expect(subscription.shipping_fee_estimate.to_f).to eq 12.34
            expect(subscription.payment_fee_estimate.to_f).to eq 9.12
          end
        end

        context "using flat percent item total calculators" do
          let(:shipping_method) {
            create(:shipping_method,
                   calculator: Calculator::FlatPercentItemTotal.new(
                     preferred_flat_percent: 10
                   ))
          }
          let(:payment_method) {
            create(:payment_method,
                   calculator: Calculator::FlatPercentItemTotal.new(
                     preferred_flat_percent: 20
                   ))
          }

          it "calculates fees based on the estimated item total and percentage provided" do
            estimator.estimate!
            expect(subscription.shipping_fee_estimate.to_f).to eq 1.5
            expect(subscription.payment_fee_estimate.to_f).to eq 3.0
          end
        end

        context "using flat percent per item calculators" do
          let(:shipping_method) {
            create(:shipping_method,
                   calculator: Calculator::FlatPercentPerItem.new(preferred_flat_percent: 5))
          }
          let(:payment_method) {
            create(:payment_method,
                   calculator: Calculator::FlatPercentPerItem.new(preferred_flat_percent: 10))
          }

          it "calculates fees based on the estimated item prices and percentage provided" do
            estimator.estimate!
            expect(subscription.shipping_fee_estimate.to_f).to eq 0.75
            expect(subscription.payment_fee_estimate.to_f).to eq 1.5
          end
        end

        context "using per item calculators" do
          let(:shipping_method) {
            create(:shipping_method,
                   calculator: Calculator::PerItem.new(preferred_amount: 1.2))
          }
          let(:payment_method) {
            create(:payment_method,
                   calculator: Calculator::PerItem.new(preferred_amount: 0.3))
          }

          it "calculates fees based on the number of items and rate provided" do
            estimator.estimate!
            expect(subscription.shipping_fee_estimate.to_f).to eq 3.6
            expect(subscription.payment_fee_estimate.to_f).to eq 0.9
          end
        end
      end
    end
  end
end
