# frozen_string_literal: true

RSpec.describe Orders::CartResetService do
  let(:distributor) { create(:distributor_enterprise) }
  let(:order) { create(:order, :with_line_item, distributor:) }

  context "if order distributor is not the requested distributor" do
    let(:new_distributor) { create(:distributor_enterprise) }

    it "empties order" do
      Orders::CartResetService.new(order, new_distributor.id.to_s).reset_distributor

      expect(order.line_items).to be_empty
    end
  end

  describe "#reset_other!" do
    it "does not reset the user" do
      new_user = create(:user)

      expect do
        described_class.new(order, distributor.id.to_s).reset_other!(new_user, nil)
      end.not_to change { order.user }
    end

    context "when user is missing" do
      it "does not reset the user" do
        expect do
          described_class.new(order, distributor.id.to_s).reset_other!(nil, nil)
        end.not_to change { order.user }
      end
    end

    context "when order email is blank" do
      it "links the order to the current user" do
        new_user = create(:user)
        order.update(email: nil)

        described_class.new(order, distributor.id.to_s).reset_other!(new_user, nil)

        expect(order.user).to eq(new_user)
      end
    end

    context "when order user is blank" do
      it "links the order to the current user" do
        new_user = create(:user)
        order.update(user: nil)

        described_class.new(order, distributor.id.to_s).reset_other!(new_user, nil)

        expect(order.user).to eq(new_user)
      end
    end

    describe "resetting the customer" do
      let(:customer) { create(:customer) }

      before do
        order.customer = customer
        order.save!
      end

      it "links the customer to the order" do
        new_customer = create(:customer)

        described_class.new(order, distributor.id.to_s).reset_other!(nil, new_customer)

        expect(order.reload.customer).to eq(new_customer)
      end

      context "when customer is missing" do
        it "removes the customer" do
          expect do
            described_class.new(order, distributor.id.to_s).reset_other!(nil, nil)
          end.to change { order.customer }.to(nil)
        end
      end

      context "with the same customer as the order's customer" do
        it "does not reset the customer" do
          expect do
            described_class.new(order, distributor.id.to_s).reset_other!(nil, customer)
          end.not_to change { order.customer }
        end
      end
    end

    context "if the order's order cycle is not in the list of visible order cycles" do
      let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
      let(:order_cycle_list) { instance_double(Shop::OrderCyclesList) }

      before do
        expect(Shop::OrderCyclesList).to receive(:new).and_return(order_cycle_list)
        order.update_attribute :order_cycle, order_cycle
      end

      it "empties order and makes order cycle nil" do
        expect(order_cycle_list).to receive(:call).and_return([])

        Orders::CartResetService.new(order, distributor.id.to_s).reset_other!(nil, nil)

        expect(order.line_items).to be_empty
        expect(order.order_cycle).to be_nil
      end

      it "selects default Order Cycle if there's one" do
        other_order_cycle = create(:simple_order_cycle, distributors: [distributor])
        expect(order_cycle_list).to receive(:call).and_return([other_order_cycle])

        Orders::CartResetService.new(order, distributor.id.to_s).reset_other!(nil, nil)

        expect(order.order_cycle).to eq other_order_cycle
      end
    end
  end
end
