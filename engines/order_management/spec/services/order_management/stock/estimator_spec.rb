# frozen_string_literal: true

require 'spec_helper'

module OrderManagement
  module Stock
    describe Estimator do
      let!(:shipping_method) { create(:shipping_method, zones: [create(:zone)] ) }
      let(:package) { build(:stock_package_fulfilled) }
      let(:order) { package.order }
      subject { Estimator.new(order) }

      context "#shipping rates" do
        before(:each) do
          shipping_method.zones.first.members.create(zoneable: order.ship_address.country)
          allow_any_instance_of(Spree::ShippingMethod).
            to receive_message_chain(:calculator, :available?).and_return(true)
          allow_any_instance_of(Spree::ShippingMethod).
            to receive_message_chain(:calculator, :compute).and_return(4.00)
          allow_any_instance_of(Spree::ShippingMethod).
            to receive_message_chain(:calculator, :preferences).
            and_return(currency: order.currency)
          allow_any_instance_of(Spree::ShippingMethod).
            to receive_message_chain(:calculator, :marked_for_destruction?)

          allow(package).to receive_messages(shipping_methods: [shipping_method])
        end

        context "the order's ship address is in the same zone" do
          it "returns shipping rates from a shipping method" do
            shipping_rates = subject.shipping_rates(package)
            expect(shipping_rates.first.cost).to eq 4.00
          end
        end

        context "the order's ship address is in a different zone" do
          it "still returns shipping rates from a shipping method" do
            shipping_method.zones.each{ |z| z.members.delete_all }
            shipping_rates = subject.shipping_rates(package)
            expect(shipping_rates.first.cost).to eq 4.00
          end
        end

        context "the calculator is not available for that order" do
          it "does not return shipping rates from a shipping method" do
            allow_any_instance_of(Spree::ShippingMethod).
              to receive_message_chain(:calculator, :available?).and_return(false)
            shipping_rates = subject.shipping_rates(package)
            expect(shipping_rates).to eq []
          end
        end

        context "the currency matches the order's currency" do
          it "returns shipping rates from a shipping method" do
            shipping_rates = subject.shipping_rates(package)
            expect(shipping_rates.first.cost).to eq 4.00
          end
        end

        context "the currency is different than the order's currency" do
          it "does not return shipping rates from a shipping method" do
            order.currency = "USD"
            shipping_rates = subject.shipping_rates(package)
            expect(shipping_rates).to eq []
          end
        end

        it "sorts shipping rates by cost" do
          shipping_methods = 3.times.map { create(:shipping_method) }
          allow(shipping_methods[0]).
            to receive_message_chain(:calculator, :compute).and_return(5.00)
          allow(shipping_methods[1]).
            to receive_message_chain(:calculator, :compute).and_return(3.00)
          allow(shipping_methods[2]).
            to receive_message_chain(:calculator, :compute).and_return(4.00)

          allow(subject).to receive(:shipping_methods).and_return(shipping_methods)

          expected_costs = %w[3.00 4.00 5.00].map(&BigDecimal.method(:new))
          expect(subject.shipping_rates(package).map(&:cost)).to eq expected_costs
        end

        context "general shipping methods" do
          let(:shipping_methods) { 2.times.map { create(:shipping_method) } }

          it "selects the most affordable shipping rate" do
            allow(shipping_methods[0]).
              to receive_message_chain(:calculator, :compute).and_return(5.00)
            allow(shipping_methods[1]).
              to receive_message_chain(:calculator, :compute).and_return(3.00)

            allow(subject).to receive(:shipping_methods).and_return(shipping_methods)

            shipping_rates = subject.shipping_rates(package)
            expect(shipping_rates.sort_by(&:cost).map(&:selected)).to eq [true, false]
          end

          it "selects the cheapest shipping rate and doesn't raise exception over nil cost" do
            allow(shipping_methods[0]).
              to receive_message_chain(:calculator, :compute).and_return(1.00)
            allow(shipping_methods[1]).
              to receive_message_chain(:calculator, :compute).and_return(nil)

            allow(subject).to receive(:shipping_methods).and_return(shipping_methods)

            subject.shipping_rates(package)
          end
        end

        context "involves backend only shipping methods" do
          let(:backend_method) { create(:shipping_method, display_on: "back_end") }
          let(:generic_method) { create(:shipping_method) }

          before do
            allow(subject).to receive(:shipping_methods).
              and_return([backend_method, generic_method])
          end

          it "does not return backend rates at all" do
            expect(subject.shipping_rates(package).map(&:shipping_method_id)).to eq([generic_method.id])
          end

          # regression for #3287
          it "doesn't select backend rates even if they're more affordable" do
            expect(subject.shipping_rates(package).map(&:selected)).to eq [true]
          end
        end

        context "includes tax adjustments if applicable" do
          let!(:tax_rate) { create(:tax_rate, zone: order.tax_zone) }

          before do
            Spree::ShippingMethod.all.each do |sm|
              sm.tax_category_id = tax_rate.tax_category_id
              sm.save
            end
            package.shipping_methods.map(&:reload)
          end


          it "links the shipping rate and the tax rate" do
            shipping_rates = subject.shipping_rates(package)
            expect(shipping_rates.first.tax_rate).to eq(tax_rate)
          end
        end
      end
    end
  end
end
