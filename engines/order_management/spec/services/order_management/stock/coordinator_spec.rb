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

      context "package" do
        it "builds, prioritizes and estimates" do
          expect(subject).to receive(:build_package).ordered
          expect(subject).to receive(:prioritize_package).ordered
          expect(subject).to receive(:estimate_package).ordered
          subject.package
        end
      end
    end
  end
end
