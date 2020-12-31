# frozen_string_literal: true

require 'spec_helper'

describe TagRule, type: :model do
  describe "validations" do
    it "requires a enterprise" do
      expect(subject).to validate_presence_of(:enterprise)
    end
  end
end
