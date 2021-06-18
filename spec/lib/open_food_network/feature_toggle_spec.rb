# frozen_string_literal: true

require 'spec_helper'

module OpenFoodNetwork
  describe FeatureToggle do
    context 'when users are not specified' do
      it "returns false when feature is undefined" do
        expect(FeatureToggle.enabled?(:foo)).to be false
      end

      it "uses Flipper configuration" do
        Flipper.enable(:foo)
        expect(FeatureToggle.enabled?(:foo)).to be true
      end
    end

    context 'when specifying users' do
      let(:insider) { build(:user) }
      let(:outsider) { build(:user, email: "different") }

      context 'and the block does not specify arguments' do
        before do
          FeatureToggle.enable(:foo) { 'return value' }
        end

        it "returns the block's return value" do
          expect(FeatureToggle.enabled?(:foo, insider)).to eq('return value')
        end
      end

      context 'and the block specifies arguments' do
        let(:users) { [insider.email] }

        before do
          FeatureToggle.enable(:foo) { |user| users.include?(user&.email) }
        end

        it "returns the block's return value" do
          expect(FeatureToggle.enabled?(:foo, insider)).to eq(true)
          expect(FeatureToggle.enabled?(:foo, outsider)).to eq(false)
          expect(FeatureToggle.enabled?(:foo, nil)).to eq(false)
        end
      end
    end
  end
end
