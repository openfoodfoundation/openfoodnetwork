# frozen_string_literal: true

require 'spec_helper'

module OrderManagement
  module Stock
    describe Coordinator do
      let!(:order) do
        build_stubbed(
          :order_with_line_items,
          distributor: build_stubbed(:distributor_enterprise)
        )
      end

      subject { Coordinator.new(order) }

      context "packages" do
        it "builds, prioritizes and estimates" do
          expect(subject).to receive(:build_packages).ordered
          expect(subject).to receive(:prioritize_packages).ordered
          expect(subject).to receive(:estimate_packages).ordered
          subject.packages
        end
      end
    end
  end
end
