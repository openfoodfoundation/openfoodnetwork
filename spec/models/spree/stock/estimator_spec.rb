# frozen_string_literal: true

require 'spec_helper'

module Spree
  module Stock
    describe Estimator do
      let!(:shipping_method) { create(:shipping_method) }
      let(:package) { build(:stock_package_fulfilled) }
      let(:order) { package.order }
      subject { Estimator.new(order) }

      context "#shipping rates" do
        before(:each) do
          shipping_method.zones.first.members.create(zoneable: order.ship_address.country)
          ShippingMethod.any_instance.stub_chain(:calculator, :available?).and_return(true)
          ShippingMethod.any_instance.stub_chain(:calculator, :compute).and_return(4.00)
          ShippingMethod.any_instance.
            stub_chain(:calculator, :preferences).and_return({ currency: "USD" })
          ShippingMethod.any_instance.stub_chain(:calculator, :marked_for_destruction?)

          package.stub(shipping_methods: [shipping_method])
        end

        context "the order's ship address is in the same zone" do
          it "returns shipping rates from a shipping method" do
            shipping_rates = subject.shipping_rates(package)
            shipping_rates.first.cost.should eq 4.00
          end
        end

        context "the order's ship address is in a different zone" do
          it "does not return shipping rates from a shipping method" do
            shipping_method.zones.each{ |z| z.members.delete_all }
            shipping_rates = subject.shipping_rates(package)
            shipping_rates.should == []
          end
        end

        context "the calculator is not available for that order" do
          it "does not return shipping rates from a shipping method" do
            ShippingMethod.any_instance.stub_chain(:calculator, :available?).and_return(false)
            shipping_rates = subject.shipping_rates(package)
            shipping_rates.should == []
          end
        end

        context "the currency matches the order's currency" do
          it "returns shipping rates from a shipping method" do
            shipping_rates = subject.shipping_rates(package)
            shipping_rates.first.cost.should eq 4.00
          end
        end

        context "the currency is different than the order's currency" do
          it "does not return shipping rates from a shipping method" do
            order.currency = "GBP"
            shipping_rates = subject.shipping_rates(package)
            shipping_rates.should == []
          end
        end

        it "sorts shipping rates by cost" do
          shipping_methods = 3.times.map { create(:shipping_method) }
          shipping_methods[0].stub_chain(:calculator, :compute).and_return(5.00)
          shipping_methods[1].stub_chain(:calculator, :compute).and_return(3.00)
          shipping_methods[2].stub_chain(:calculator, :compute).and_return(4.00)

          subject.stub(:shipping_methods).and_return(shipping_methods)

          expected_costs = %w[3.00 4.00 5.00].map(&BigDecimal.method(:new))
          expect(subject.shipping_rates(package).map(&:cost)).to eq expected_costs
        end

        context "general shipping methods" do
          let(:shipping_methods) { 2.times.map { create(:shipping_method) } }

          it "selects the most affordable shipping rate" do
            shipping_methods[0].stub_chain(:calculator, :compute).and_return(5.00)
            shipping_methods[1].stub_chain(:calculator, :compute).and_return(3.00)

            subject.stub(:shipping_methods).and_return(shipping_methods)

            shipping_rates = subject.shipping_rates(package)
            expect(shipping_rates.sort_by(&:cost).map(&:selected)).to eq [true, false]
          end

          it "selects the cheapest shipping rate and doesn't raise exception over nil cost" do
            shipping_methods[0].stub_chain(:calculator, :compute).and_return(1.00)
            shipping_methods[1].stub_chain(:calculator, :compute).and_return(nil)

            subject.stub(:shipping_methods).and_return(shipping_methods)

            subject.shipping_rates(package)
          end
        end

        context "involves backend only shipping methods" do
          let(:backend_method) { create(:shipping_method, display_on: "back_end") }
          let(:generic_method) { create(:shipping_method) }

          # regression for #3287
          it "doesn't select backend rates even if they're more affordable" do
            backend_method.stub_chain(:calculator, :compute).and_return(0.00)
            generic_method.stub_chain(:calculator, :compute).and_return(5.00)

            subject.stub(:shipping_methods).and_return([backend_method, generic_method])

            expect(subject.shipping_rates(package).map(&:selected)).to eq [false, true]
          end
        end
      end
    end
  end
end
