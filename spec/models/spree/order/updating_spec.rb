# frozen_string_literal: true

require 'spec_helper'

describe Spree::Order do
  let(:order) { build(:order) }

  context "#update!" do
    let(:line_items) { [build(:line_item, amount: 5)] }

    context "when there are update hooks" do
      before { Spree::Order.register_update_hook :foo }
      after { Spree::Order.update_hooks.clear }
      it "should call each of the update hooks" do
        order.should_receive :foo
        order.update!
      end
    end
  end
end
