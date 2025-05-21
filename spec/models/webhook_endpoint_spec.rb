# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebhookEndpoint do
  describe "validations" do
    it { is_expected.to validate_presence_of(:url) }
  end
end
