require 'spec_helper'

describe TagRule, type: :model do
  let!(:tag_rule) { create(:tag_rule) }

  describe "validations" do
    it "requires a enterprise" do
      expect(tag_rule).to validate_presence_of :enterprise
    end
  end
end
