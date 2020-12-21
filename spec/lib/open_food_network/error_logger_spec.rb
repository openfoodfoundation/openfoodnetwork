# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/error_logger'

module OpenFoodNetwork
  describe ErrorLogger do
    let(:error) { StandardError.new("Test") }

    it "notifies Bugsnag" do
      expect(Bugsnag).to receive(:notify).with(error)

      ErrorLogger.notify(error)
    end
  end
end
