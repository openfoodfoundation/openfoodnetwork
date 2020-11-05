# frozen_string_literal: true

require 'spec_helper'

describe OrderCycleWarning do
  let(:user) { create(:user) }
  let(:subject) { OrderCycleWarning }
  let!(:distributor) { create(:enterprise, owner: user) }
  let!(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }

  describe "checking if user's managed order cycles have distributors not ready for checkout" do
    context "with an invalid distributor" do
      it "returns a warning message" do
        expect(subject.new(user).call).to eq(
          I18n.t(:active_distributors_not_ready_for_checkout_message_singular,
                 distributor_names: distributor.name)
        )
      end
    end

    context "with a valid distributor" do
      let!(:distributor) {
        create(:distributor_enterprise,
               shipping_methods: [create(:shipping_method)],
               payment_methods: [create(:payment_method)])
      }

      it "returns nil" do
        expect(subject.new(user).call).to eq nil
      end
    end
  end
end
