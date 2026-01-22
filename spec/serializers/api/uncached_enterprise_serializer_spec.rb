# frozen_string_literal: true

RSpec.describe Api::UncachedEnterpriseSerializer do
  let(:serializer) {
    described_class.new enterprise, { data: OpenFoodNetwork::EnterpriseInjectionData.new }
  }
  let(:enterprise) { create :enterprise }

  before do
    allow_any_instance_of(OpenFoodNetwork::EnterpriseInjectionData).to(
      receive(:earliest_closing_times).
        and_return(data)
    )
  end

  describe '#orders_close_at' do
    context "for an enterprise with an active order cycle" do
      let(:order_cycle) { create :open_order_cycle, coordinator: enterprise }
      let(:data) { { enterprise.id => order_cycle.orders_close_at } }

      it "returns a closing time for an enterprise" do
        expect(serializer.orders_close_at).to eq order_cycle.orders_close_at
      end
    end

    context "for an enterprise without an active order cycle" do
      let(:data) { {} }

      it "returns nil for an enterprise without a closing time" do
        expect(serializer.orders_close_at).to be_nil
      end
    end
  end
end
