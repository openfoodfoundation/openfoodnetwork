describe OrderCycleForm do
  describe "save" do
    describe "creating a new order cycle from params" do
      let(:shop) { create(:enterprise) }
      let(:order_cycle) { OrderCycle.new }
      let(:form) { OrderCycleForm.new(order_cycle, params) }

      context "when creation is successful" do
        let(:params) { { order_cycle: { name: "Test Order Cycle", coordinator_id: shop.id } } }

        it "returns true" do
          expect do
            expect(form.save).to be true
          end.to change(OrderCycle, :count).by(1)
        end
      end

      context "when creation fails" do
        let(:params) { { order_cycle: { name: "Test Order Cycle" } } }

        it "returns false" do
          expect do
            expect(form.save).to be false
          end.to_not change(OrderCycle, :count)
        end
      end
    end

    describe "updating an existing order cycle from params" do
      let(:shop) { create(:enterprise) }
      let(:order_cycle) { create(:simple_order_cycle, name: "Old Name") }
      let(:form) { OrderCycleForm.new(order_cycle, params) }

      context "when update is successful" do
        let(:params) { { order_cycle: { name: "Test Order Cycle", coordinator_id: shop.id } } }

        it "returns true" do
          expect do
            expect(form.save).to be true
          end.to change(order_cycle.reload, :name).to("Test Order Cycle")
        end
      end

      context "when updating fails" do
        let(:params) { { order_cycle: { name: nil } } }

        it "returns false" do
          expect do
            expect(form.save).to be false
          end.to_not change{ order_cycle.reload.name }
        end
      end
    end
  end
end
