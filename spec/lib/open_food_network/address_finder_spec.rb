# frozen_string_literal: true

require 'open_food_network/address_finder'

RSpec.describe OpenFoodNetwork::AddressFinder do
  let(:email) { 'test@example.com' }

  describe "initialisation" do
    let(:user) { create(:user) }
    let(:customer) { create(:customer) }

    context "when passed any combination of instances of String, Customer or Spree::User" do
      let(:finder1) { described_class.new(email:, customer:, user:) }

      it "stores arguments" do
        expect(finder1.email).to eq email
        expect(finder1.customer).to be customer
        expect(finder1.user).to be user
      end
    end
  end

  describe "fallback_bill_address" do
    let(:finder) { described_class.new(email:) }
    let(:address) { double(:address, clone: 'address_clone') }

    context "when a last_used_bill_address is found" do
      before { allow(finder).to receive(:last_used_bill_address) { address } }

      it "returns a clone of the bill_address" do
        expect(finder.__send__(:fallback_bill_address)).to eq "address_clone"
      end
    end

    context "when no last_used_bill_address is found" do
      before { allow(finder).to receive(:last_used_bill_address) { nil } }

      it "returns a new empty address" do
        expect(finder.__send__(:fallback_bill_address)).to eq Spree::Address.default
      end
    end
  end

  describe "fallback_ship_address" do
    let(:finder) { described_class.new(email:) }
    let(:address) { double(:address, clone: 'address_clone') }

    context "when a last_used_ship_address is found" do
      before { allow(finder).to receive(:last_used_ship_address) { address } }

      it "returns a clone of the ship_address" do
        expect(finder.__send__(:fallback_ship_address)).to eq "address_clone"
      end
    end

    context "when no last_used_ship_address is found" do
      before { allow(finder).to receive(:last_used_ship_address) { nil } }

      it "returns a new empty address" do
        expect(finder.__send__(:fallback_ship_address)).to eq Spree::Address.default
      end
    end
  end

  describe "last_used_bill_address" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:address) { create(:address) }
    let(:order) {
      create(:completed_order_with_totals, user: nil, email:, distributor:,
                                           bill_address: nil)
    }
    let(:finder) { described_class.new(email:) }

    context "when searching by email is not allowed" do
      before do
        allow(finder).to receive(:allow_search_by_email?) { false }
      end

      context "and an order with a bill address exists" do
        before do
          order.update_attribute(:bill_address, address)
        end

        it "returns nil" do
          expect(finder.__send__(:last_used_bill_address)).to eq nil
        end
      end
    end

    context "when searching by email is allowed" do
      before do
        allow(finder).to receive(:allow_search_by_email?) { true }
      end

      context "and an order with a bill address exists" do
        before { order.update_attribute(:bill_address, address) }

        it "returns the bill_address" do
          expect(finder.__send__(:last_used_bill_address)).to eq address
        end
      end

      context "and an order without a bill address exists" do
        before { order }

        it "return nil" do
          expect(finder.__send__(:last_used_bill_address)).to eq nil
        end
      end

      context "when no orders exist" do
        it "returns nil" do
          expect(finder.__send__(:last_used_bill_address)).to eq nil
        end
      end
    end
  end

  describe "last_used_ship_address" do
    let(:address) { create(:address) }
    let(:distributor) { create(:distributor_enterprise) }
    let(:finder) { described_class.new(email:) }

    context "when searching by email is not allowed" do
      before do
        allow(finder).to receive(:allow_search_by_email?) { false }
      end

      context "and an order with a required ship address exists" do
        let(:order) {
          create(:shipped_order, user: nil, email:, distributor:, shipments: [],
                                 ship_address: address)
        }

        before do
          order.shipping_method.update_attribute(:require_ship_address, true)
        end

        it "returns nil" do
          expect(finder.__send__(:last_used_ship_address)).to eq nil
        end
      end
    end

    context "when searching by email is allowed" do
      before do
        allow(finder).to receive(:allow_search_by_email?) { true }
      end

      context "and an order with a ship address exists" do
        let(:order) {
          create(:shipped_order, user: nil, email:, distributor:, shipments: [],
                                 ship_address: address)
        }

        context "and the shipping method requires an address" do
          before { order.shipping_method.update_attribute(:require_ship_address, true) }

          it "returns the ship_address" do
            expect(finder.__send__(:last_used_ship_address)).to eq address
          end
        end

        context "and the shipping method does not require an address" do
          before { order.shipping_method.update_attribute(:require_ship_address, false) }

          it "returns nil" do
            expect(finder.__send__(:last_used_ship_address)).to eq nil
          end
        end
      end

      context "and an order without a ship address exists" do
        let!(:order) {
          create(:shipped_order, user: nil, email:, distributor:, shipments: [],
                                 ship_address: nil)
        }

        it "return nil" do
          expect(finder.__send__(:last_used_ship_address)).to eq nil
        end
      end

      context "when no orders exist" do
        it "returns nil" do
          expect(finder.__send__(:last_used_ship_address)).to eq nil
        end
      end
    end
  end

  describe "allow_search_by_email?" do
    let(:finder) { described_class.new }
    context "when an email address has been provided" do
      before{ allow(finder).to receive(:email) { "email@email.com" } }

      context "when a customer has been provided" do
        let(:customer) { double(:customer) }
        before{ allow(finder).to receive(:customer) { customer } }

        context "when the customer email matches the raw email" do
          before{ allow(customer).to receive(:email) { "email@email.com" } }
          it "returns true" do
            expect(finder.__send__(:allow_search_by_email?)).to be true
          end
        end

        context "when the customer email does not match the raw email" do
          before{ allow(customer).to receive(:email) { "nah@email.com" } }
          it "returns false" do
            expect(finder.__send__(:allow_search_by_email?)).to be false
          end
        end
      end

      context "when a user has been provided" do
        let(:user) { double(:user) }
        before{ allow(finder).to receive(:user) { user } }

        context "when the user email matches the raw email" do
          before{ allow(user).to receive(:email) { "email@email.com" } }
          it "returns true" do
            expect(finder.__send__(:allow_search_by_email?)).to be true
          end
        end

        context "when the user email does not match the raw email" do
          before{ allow(user).to receive(:email) { "nah@email.com" } }
          it "returns false" do
            expect(finder.__send__(:allow_search_by_email?)).to be false
          end
        end
      end

      context "when neither a customer nor a user has been provided" do
        it "returns false" do
          expect(finder.__send__(:allow_search_by_email?)).to be false
        end
      end
    end

    context "when an email address is not provided" do
      it "returns false" do
        expect(finder.__send__(:allow_search_by_email?)).to be false
      end
    end
  end
end
