require 'spec_helper'

describe StandingOrder, type: :model do
  describe "cancel" do
    let!(:standing_order) { create(:standing_order) }
    let!(:proxy_order1) { create(:proxy_order, order_cycle: create(:simple_order_cycle)) }
    let!(:proxy_order2) { create(:proxy_order, order_cycle: create(:simple_order_cycle)) }

    before do
      allow(standing_order).to receive(:proxy_orders) { [proxy_order1, proxy_order2] }
    end

    context "when all standing order orders can be cancelled" do
      before { allow(proxy_order1).to receive(:cancel) { true } }
      before { allow(proxy_order2).to receive(:cancel) { true } }

      it "marks the standing order as cancelled and calls #cancel on all proxy_orders" do
        standing_order.cancel
        expect(standing_order.reload.canceled_at).to be_within(5.seconds).of Time.now
        expect(proxy_order1).to have_received(:cancel)
        expect(proxy_order2).to have_received(:cancel)
      end
    end

    context "when a standing order order cannot be cancelled" do
      before { allow(proxy_order1).to receive(:cancel).and_raise("Some error") }
      before { allow(proxy_order2).to receive(:cancel) { true } }

      it "aborts the transaction" do
        # ie. canceled_at remains as nil, #cancel not called on second standing order order
        expect{standing_order.cancel}.to raise_error "Some error"
        expect(standing_order.reload.canceled_at).to be nil
        expect(proxy_order1).to have_received(:cancel)
        expect(proxy_order2).to_not have_received(:cancel)
      end
    end
  end

  describe "state" do
    let(:standing_order) { StandingOrder.new }

    context "when the standing order has been cancelled" do
      before { allow(standing_order).to receive(:canceled_at) { Time.zone.now } }

      it "returns 'canceled'" do
        expect(standing_order.state).to eq 'canceled'
      end
    end

    context "when the standing order has not been cancelled" do
      before { allow(standing_order).to receive(:canceled_at) { nil } }

      context "and the standing order has been paused" do
        before { allow(standing_order).to receive(:paused_at) { Time.zone.now } }

        it "returns 'paused'" do
          expect(standing_order.state).to eq 'paused'
        end
      end

      context "and the standing order has not been paused" do
        before { allow(standing_order).to receive(:paused_at) { nil } }

        context "and the standing order has no begins_at date" do
          before { allow(standing_order).to receive(:begins_at) { nil } }

          it "returns nil" do
            expect(standing_order.state).to be nil
          end
        end

        context "and the standing order has a begins_at date in the future" do
          before { allow(standing_order).to receive(:begins_at) { 1.minute.from_now } }

          it "returns 'pending'" do
            expect(standing_order.state).to eq 'pending'
          end
        end

        context "and the standing order has a begins_at date in the past" do
          before { allow(standing_order).to receive(:begins_at) { 1.minute.ago } }

          context "and the standing order has no ends_at date set" do
            before { allow(standing_order).to receive(:ends_at) { nil } }

            it "returns 'active'" do
              expect(standing_order.state).to eq 'active'
            end
          end

          context "and the standing order has an ends_at date in the future" do
            before { allow(standing_order).to receive(:ends_at) { 1.minute.from_now } }

            it "returns 'active'" do
              expect(standing_order.state).to eq 'active'
            end
          end

          context "and the standing order has an ends_at date in the past" do
            before { allow(standing_order).to receive(:ends_at) { 1.minute.ago } }

            it "returns 'ended'" do
              expect(standing_order.state).to eq 'ended'
            end
          end
        end
      end
    end
  end
end
