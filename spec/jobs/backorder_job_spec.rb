# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BackorderJob do
  let(:order) { create(:completed_order_with_totals) }

  describe ".check_stock" do
    it "ignores products without semantic link" do
      BackorderJob.check_stock(order)
    end
  end
end
