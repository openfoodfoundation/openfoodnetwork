require 'spec_helper'

describe FeatureFlags do
  let(:user) { build_stubbed(:user) }
  let(:feature_flags) { described_class.new(user) }

  describe '#product_import_enabled?' do
    context 'when the user is superadmin' do
      before do
        allow(user).to receive(:superadmin?) { true }
      end

      it 'returns true' do
        expect(feature_flags.product_import_enabled?).to eq(true)
      end
    end

    context 'when the user is not superadmin' do
      before do
        allow(user).to receive(:superadmin?) { false }
      end

      it 'returns false' do
        expect(feature_flags.product_import_enabled?).to eq(false)
      end
    end
  end

  describe "#enterprise_fee_summary_enabled?" do
    context "when the user is superadmin" do
      let!(:user) { create(:admin_user) }

      it "returns true" do
        expect(feature_flags).to be_enterprise_fee_summary_enabled
      end
    end

    context "when the user is not superadmin" do
      let!(:user) { create(:user) }

      it "returns false" do
        expect(feature_flags).not_to be_enterprise_fee_summary_enabled
      end
    end
  end
end
