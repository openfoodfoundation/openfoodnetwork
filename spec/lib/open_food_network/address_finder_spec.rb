# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/address_finder'

module OpenFoodNetwork
  describe AddressFinder do
    let(:email) { 'test@example.com' }

    describe "initialisation" do
      let(:user) { create(:user) }
      let(:customer) { create(:customer) }

      context "when passed any combination of instances of String, Customer or Spree::User" do
        let(:finder1) { AddressFinder.new(email, customer, user) }
        let(:finder2) { AddressFinder.new(customer, user, email) }

        it "stores arguments based on their class" do
          expect(finder1.email).to eq email
          expect(finder2.email).to eq email
          expect(finder1.customer).to be customer
          expect(finder2.customer).to be customer
          expect(finder1.user).to be user
          expect(finder2.user).to be user
        end
      end

      context "when passed multiples instances of a class" do
        let(:email2) { 'test2@example.com' }
        let(:user2) { create(:user) }
        let(:customer2) { create(:customer) }
        let(:finder1) { AddressFinder.new(user2, email, email2, customer2, user, customer) }
        let(:finder2) { AddressFinder.new(email2, customer, user, email, user2, customer2) }

        it "only stores the first encountered instance of a given class" do
          expect(finder1.email).to eq email
          expect(finder2.email).to eq email2
          expect(finder1.customer).to be customer2
          expect(finder2.customer).to be customer
          expect(finder1.user).to be user2
          expect(finder2.user).to be user
        end
      end
    end

    describe "fallback_bill_address" do
      let(:finder) { AddressFinder.new(email) }
      let(:address) { double(:address, clone: 'address_clone') }

      context "when a last_used_bill_address is found" do
        before { allow(finder).to receive(:last_used_bill_address) { address } }

        it "returns a clone of the bill_address" do
          expect(finder.send(:fallback_bill_address)).to eq "address_clone"
        end
      end

      context "when no last_used_bill_address is found" do
        before { allow(finder).to receive(:last_used_bill_address) { nil } }

        it "returns a new empty address" do
          expect(finder.send(:fallback_bill_address)).to eq Spree::Address.default
        end
      end
    end

    describe "fallback_ship_address" do
      let(:finder) { AddressFinder.new(email) }
      let(:address) { double(:address, clone: 'address_clone') }

      context "when a last_used_ship_address is found" do
        before { allow(finder).to receive(:last_used_ship_address) { address } }

        it "returns a clone of the ship_address" do
          expect(finder.send(:fallback_ship_address)).to eq "address_clone"
        end
      end

      context "when no last_used_ship_address is found" do
        before { allow(finder).to receive(:last_used_ship_address) { nil } }

        it "returns a new empty address" do
          expect(finder.send(:fallback_ship_address)).to eq Spree::Address.default
        end
      end
    end

    describe "last_used_bill_address" do
      let(:distributor) { create(:distributor_enterprise) }
      let(:address) { create(:address) }
      let(:order) {
        create(:completed_order_with_totals, user: nil, email: email, distributor: distributor,
                                             bill_address: nil)
      }
      let(:finder) { AddressFinder.new(email) }

      context "when searching by email is not allowed" do
        before do
          allow(finder).to receive(:allow_search_by_email?) { false }
        end

        context "and an order with a bill address exists" do
          before do
            order.update_attribute(:bill_address, address)
          end

          it "returns nil" do
            expect(finder.send(:last_used_bill_address)).to eq nil
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
            expect(finder.send(:last_used_bill_address)).to eq address
          end
        end

        context "and an order without a bill address exists" do
          before { order }

          it "return nil" do
            expect(finder.send(:last_used_bill_address)).to eq nil
          end
        end

        context "when no orders exist" do
          it "returns nil" do
            expect(finder.send(:last_used_bill_address)).to eq nil
          end
        end
      end
    end

    describe "last_used_ship_address" do
      let(:address) { create(:address) }
      let(:distributor) { create(:distributor_enterprise) }
      let(:finder) { AddressFinder.new(email) }

      context "when searching by email is not allowed" do
        before do
          allow(finder).to receive(:allow_search_by_email?) { false }
        end

        context "and an order with a required ship address exists" do
          let(:order) {
            create(:shipped_order, user: nil, email: email, distributor: distributor, shipments: [],
                                   ship_address: address)
          }

          before do
            order.shipping_method.update_attribute(:require_ship_address, true)
          end

          it "returns nil" do
            expect(finder.send(:last_used_ship_address)).to eq nil
          end
        end
      end

      context "when searching by email is allowed" do
        before do
          allow(finder).to receive(:allow_search_by_email?) { true }
        end

        context "and an order with a ship address exists" do
          let(:order) {
            create(:shipped_order, user: nil, email: email, distributor: distributor, shipments: [],
                                   ship_address: address)
          }

          context "and the shipping method requires an address" do
            before { order.shipping_method.update_attribute(:require_ship_address, true) }

            it "returns the ship_address" do
              expect(finder.send(:last_used_ship_address)).to eq address
            end
          end

          context "and the shipping method does not require an address" do
            before { order.shipping_method.update_attribute(:require_ship_address, false) }

            it "returns nil" do
              expect(finder.send(:last_used_ship_address)).to eq nil
            end
          end
        end

        context "and an order without a ship address exists" do
          let!(:order) {
            create(:shipped_order, user: nil, email: email, distributor: distributor, shipments: [],
                                   ship_address: nil)
          }

          it "return nil" do
            expect(finder.send(:last_used_ship_address)).to eq nil
          end
        end

        context "when no orders exist" do
          it "returns nil" do
            expect(finder.send(:last_used_ship_address)).to eq nil
          end
        end
      end
    end

    describe "allow_search_by_email?" do
      let(:finder) { AddressFinder.new }
      context "when an email address has been provided" do
        before{ allow(finder).to receive(:email) { "email@email.com" } }

        context "when a customer has been provided" do
          let(:customer) { double(:customer) }
          before{ allow(finder).to receive(:customer) { customer } }

          context "when the customer email matches the raw email" do
            before{ allow(customer).to receive(:email) { "email@email.com" } }
            it "returns true" do
              expect(finder.send(:allow_search_by_email?)).to be true
            end
          end

          context "when the customer email does not match the raw email" do
            before{ allow(customer).to receive(:email) { "nah@email.com" } }
            it "returns false" do
              expect(finder.send(:allow_search_by_email?)).to be false
            end
          end
        end

        context "when a user has been provided" do
          let(:user) { double(:user) }
          before{ allow(finder).to receive(:user) { user } }

          context "when the user email matches the raw email" do
            before{ allow(user).to receive(:email) { "email@email.com" } }
            it "returns true" do
              expect(finder.send(:allow_search_by_email?)).to be true
            end
          end

          context "when the user email does not match the raw email" do
            before{ allow(user).to receive(:email) { "nah@email.com" } }
            it "returns false" do
              expect(finder.send(:allow_search_by_email?)).to be false
            end
          end
        end

        context "when neither a customer nor a user has been provided" do
          it "returns false" do
            expect(finder.send(:allow_search_by_email?)).to be false
          end
        end
      end

      context "when an email address is not provided" do
        it "returns false" do
          expect(finder.send(:allow_search_by_email?)).to be false
        end
      end
    end
  end
end
