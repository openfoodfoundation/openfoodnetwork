require 'spec_helper'

describe Admin::StandingOrdersHelper, type: :helper do
  describe "checking if setup is complete for any [shop]" do
    let(:shop) { create(:distributor_enterprise) }
    let(:customer) { create(:customer, enterprise: shop) }
    let(:shipping_method) { create(:shipping_method, distributors: [shop]) }
    let(:payment_method) { create(:payment_method, distributors: [shop]) }
    let(:schedule) { create(:schedule, order_cycles: [create(:simple_order_cycle, coordinator: shop)] ) }

    context "when a shop has no shipping methods present" do
      before { customer; payment_method; schedule }
      it { expect(helper.standing_orders_setup_complete?([shop])).to be false }
    end

    context "when a shop has no payment methods present" do
      before { customer; shipping_method; schedule }
      it { expect(helper.standing_orders_setup_complete?([shop])).to be false }
    end

    context "when a shop has no customers present" do
      before { shipping_method; payment_method; schedule }
      it { expect(helper.standing_orders_setup_complete?([shop])).to be false }
    end

    context "when a shop does not coordinate any schedules" do
      before { customer; shipping_method; payment_method; }
      it { expect(helper.standing_orders_setup_complete?([shop])).to be false }
    end

    context "when a shop meets all requirements" do
      before { customer; shipping_method; payment_method; schedule }
      let(:some_other_shop) { create(:distributor_enterprise) }

      context "but it is not passed in" do
        it { expect(helper.standing_orders_setup_complete?([some_other_shop])).to be false }
      end

      context "and it is passed in" do
        it { expect(helper.standing_orders_setup_complete?([shop])).to be true }
      end

      context "and it is passed in with other shops that do not meet the requirements" do
        it { expect(helper.standing_orders_setup_complete?([shop, some_other_shop])).to be true }
      end
    end
  end
end
