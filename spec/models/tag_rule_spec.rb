# frozen_string_literal: true

require 'spec_helper'

# This is used to test non implemented methods
class TestTagRule < TagRule; end

RSpec.describe TagRule do
  describe "validations" do
    it "requires a enterprise" do
      expect(subject).to belong_to(:enterprise)
    end
  end

  describe '#tags' do
    subject(:rule) { TestTagRule.new }

    it "raises not implemented error" do
      expect{ rule.tags }.to raise_error(NotImplementedError, 'please use concrete TagRule')
    end
  end
end
