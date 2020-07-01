# frozen_string_literal: true

require 'spec_helper'

module Spree
  module Stock
    describe Coordinator do
      let!(:order) { create(:order_with_line_items, distributor: create(:distributor_enterprise)) }

      subject { Coordinator.new(order) }

      context "packages" do
        it "builds, prioritizes and estimates" do
          subject.should_receive(:build_packages).ordered
          subject.should_receive(:prioritize_packages).ordered
          subject.should_receive(:estimate_packages).ordered
          subject.packages
        end
      end
    end
  end
end
