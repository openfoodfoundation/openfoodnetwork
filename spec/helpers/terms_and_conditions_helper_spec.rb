# frozen_string_literal: true

RSpec.describe TermsAndConditionsHelper do
  describe "#platform_terms_required?" do
    context 'when ToS file is present' do
      before do
        allow(TermsOfServiceFile).to receive(:exists?).and_return(true)
      end
      it "returns true" do
        expect(Spree::Config).to receive(:shoppers_require_tos).and_return(true)
        expect(helper.platform_terms_required?).to eq true
      end

      it "returns false" do
        expect(Spree::Config).to receive(:shoppers_require_tos).and_return(false)
        expect(helper.platform_terms_required?).to eq false
      end
    end
    context 'when ToS file is not present' do
      before do
        allow(TermsOfServiceFile).to receive(:exists?).and_return(false)
      end

      it "returns false" do
        expect(Spree::Config).not_to receive(:shoppers_require_tos)
        expect(helper.platform_terms_required?).to eq false
      end
    end
  end
end
