# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TagRule, type: :model do
  describe "validations" do
    it "requires a enterprise" do
      expect(subject).to belong_to(:enterprise)
    end
  end
end
