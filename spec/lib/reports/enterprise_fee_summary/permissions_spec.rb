# frozen_string_literal: true

require "spec_helper"

describe Reporting::Reports::EnterpriseFeeSummary::Permissions do
  let!(:order_cycle) { create(:simple_order_cycle) }
  let!(:incoming_exchange) { create(:exchange, incoming: true, order_cycle: order_cycle) }
  let!(:outgoing_exchange) { create(:exchange, incoming: false, order_cycle: order_cycle) }

  # The factory for order cycle uses the first distributor it finds in the database, if it exists.
  # However, for this example group, we need to make sure that the coordinator for the second order
  # cycle is not the same as the one in the first.
  let!(:another_coordinator) { create(:distributor_enterprise) }

  let!(:another_order_cycle) { create(:simple_order_cycle, coordinator: another_coordinator) }
  let!(:another_incoming_exchange) do
    create(:exchange, incoming: true, order_cycle: another_order_cycle)
  end
  let!(:another_outgoing_exchange) do
    create(:exchange, incoming: false, order_cycle: another_order_cycle)
  end

  describe "permissions for order cycles" do
    it "allows admin" do
      user = create(:admin_user)
      authorizer = described_class.new(user)
      expect(authorizer.allowed_order_cycles).to include(order_cycle)
    end

    it "allows coordinator of the order cycle" do
      user = order_cycle.coordinator.owner
      authorizer = described_class.new(user)
      expect(authorizer.allowed_order_cycles).to include(order_cycle)
    end

    it "allows sender of incoming exchange" do
      user = incoming_exchange.sender.owner
      authorizer = described_class.new(user)
      expect(authorizer.allowed_order_cycles).to include(order_cycle)
    end

    it "allows receiver of outgoing exchange" do
      user = outgoing_exchange.receiver.owner
      authorizer = described_class.new(user)
      expect(authorizer.allowed_order_cycles).to include(order_cycle)
    end

    it "does not allow coordinator of another order cycle" do
      user = another_order_cycle.coordinator.owner
      authorizer = described_class.new(user)
      expect(authorizer.allowed_order_cycles).not_to include(order_cycle)
    end

    it "does not allow sender of incoming exchange of another order cycle" do
      user = another_incoming_exchange.sender.owner
      authorizer = described_class.new(user)
      expect(authorizer.allowed_order_cycles).not_to include(order_cycle)
    end

    it "does not allow receiver of outgoing exchange of another order cycle" do
      user = another_outgoing_exchange.receiver.owner
      authorizer = described_class.new(user)
      expect(authorizer.allowed_order_cycles).not_to include(order_cycle)
    end
  end

  describe "permissions for properties related to the order cycle" do
    let(:user) { create(:user) }
    let(:authorizer) do
      described_class.new(user).tap do |instance|
        allow(instance).to receive(:allowed_order_cycles) { [order_cycle] }
      end
    end

    describe "allowed distributors" do
      it "includes distributor of allowed order cycle" do
        expect(authorizer.allowed_distributors).to include(outgoing_exchange.receiver)
      end

      it "does not include distributor of order cycle that is not allowed" do
        expect(authorizer.allowed_distributors).not_to include(another_outgoing_exchange.receiver)
      end
    end

    describe "allowed producers" do
      it "includes supplier of allowed order cycle" do
        expect(authorizer.allowed_producers).to include(incoming_exchange.sender)
      end

      it "does not include supplier of order cycle that is not allowed" do
        expect(authorizer.allowed_producers).not_to include(another_incoming_exchange.sender)
      end
    end

    describe "allowed enterprise fees" do
      context "when coordinator fee for order cycle" do
        let!(:coordinator_fee) do
          create(:enterprise_fee, enterprise: order_cycle.coordinator).tap do |fee|
            order_cycle.coordinator_fees << fee
          end
        end

        let!(:another_coordinator_fee) do
          create(:enterprise_fee, enterprise: another_order_cycle.coordinator).tap do |fee|
            another_order_cycle.coordinator_fees << fee
          end
        end

        it "includes enterprise fee in allowed order cycle" do
          expect(authorizer.allowed_enterprise_fees).to include(coordinator_fee)
        end

        it "does not include enterprise fee in order cycle that is not allowed" do
          expect(authorizer.allowed_enterprise_fees).not_to include(another_coordinator_fee)
        end
      end

      context "when enterprise fee for incoming exchange" do
        let!(:exchange_fee) do
          create(:enterprise_fee, enterprise: incoming_exchange.sender).tap do |fee|
            incoming_exchange.enterprise_fees << fee
          end
        end

        let!(:another_exchange_fee) do
          create(:enterprise_fee, enterprise: another_incoming_exchange.sender).tap do |fee|
            another_incoming_exchange.enterprise_fees << fee
          end
        end

        it "includes enterprise fee in allowed order cycle" do
          expect(authorizer.allowed_enterprise_fees).to include(exchange_fee)
        end

        it "does not include enterprise fee in order cycle that is not allowed" do
          expect(authorizer.allowed_enterprise_fees).not_to include(another_exchange_fee)
        end
      end

      context "when enterprise fee for outgoing exchange" do
        let!(:exchange_fee) do
          create(:enterprise_fee, enterprise: outgoing_exchange.receiver).tap do |fee|
            outgoing_exchange.enterprise_fees << fee
          end
        end

        let!(:another_exchange_fee) do
          create(:enterprise_fee, enterprise: another_outgoing_exchange.receiver).tap do |fee|
            another_outgoing_exchange.enterprise_fees << fee
          end
        end

        it "includes enterprise fee in allowed order cycle" do
          expect(authorizer.allowed_enterprise_fees).to include(exchange_fee)
        end

        it "does not include enterprise fee in order cycle that is not allowed" do
          expect(authorizer.allowed_enterprise_fees).not_to include(another_exchange_fee)
        end
      end
    end

    describe "allowed shipping methods" do
      it "includes shipping methods of distributors in allowed order cycle" do
        shipping_method = create(:shipping_method, distributors: [outgoing_exchange.receiver])
        expect(authorizer.allowed_shipping_methods).to include(shipping_method)
      end

      it "does not include shipping methods of suppliers in allowed order cycle" do
        shipping_method = create(:shipping_method, distributors: [incoming_exchange.sender])
        expect(authorizer.allowed_shipping_methods).not_to include(shipping_method)
      end

      it "does not include shipping methods of coordinator of allowed order cycle" do
        shipping_method = create(:shipping_method, distributors: [order_cycle.coordinator])
        expect(authorizer.allowed_shipping_methods).not_to include(shipping_method)
      end

      it "does not include shipping methods of distributors in order cycle that is not allowed" do
        shipping_method = create(:shipping_method,
                                 distributors: [another_outgoing_exchange.receiver])
        expect(authorizer.allowed_shipping_methods).not_to include(shipping_method)
      end
    end

    describe "allowed payment methods" do
      it "includes payment methods of distributors in allowed order cycle" do
        payment_method = create(:payment_method, distributors: [outgoing_exchange.receiver])
        expect(authorizer.allowed_payment_methods).to include(payment_method)
      end

      it "does not include payment methods of suppliers in allowed order cycle" do
        payment_method = create(:payment_method, distributors: [incoming_exchange.sender])
        expect(authorizer.allowed_payment_methods).not_to include(payment_method)
      end

      it "does not include payment methods of coordinator of allowed order cycle" do
        payment_method = create(:payment_method, distributors: [order_cycle.coordinator])
        expect(authorizer.allowed_payment_methods).not_to include(payment_method)
      end

      it "does not include payment methods of distributors in order cycle that is not allowed" do
        payment_method = create(:payment_method, distributors: [another_outgoing_exchange.receiver])
        expect(authorizer.allowed_payment_methods).not_to include(payment_method)
      end
    end
  end
end
