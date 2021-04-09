# frozen_string_literal: true

require 'spec_helper'

module OpenFoodNetwork
  describe FeatureToggle do
    context 'when users are not specified' do
      it "returns true when feature is on" do
        stub_foo("true")
        expect(FeatureToggle.enabled?(:foo)).to be true
      end

      it "returns false when feature is off" do
        stub_foo("false")
        expect(FeatureToggle.enabled?(:foo)).to be false
      end

      it "returns false when feature is unspecified" do
        stub_foo("maybe")
        expect(FeatureToggle.enabled?(:foo)).to be false
      end

      it "returns false when feature is undefined" do
        expect(FeatureToggle.enabled?(:foo)).to be false
      end

      it "uses Flipper configuration" do
        Flipper.enable(:foo)
        expect(FeatureToggle.enabled?(:foo)).to be true
      end

      it "uses Flipper over static config" do
        Flipper.enable(:foo, false)
        stub_foo("true")
        expect(FeatureToggle.enabled?(:foo)).to be false
      end

      def stub_foo(value)
        allow(ENV).to receive(:fetch).with("OFN_FEATURE_FOO", nil).and_return(value)
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
