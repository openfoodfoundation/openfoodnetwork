# frozen_string_literal: true

RSpec.describe MailerHelper do
  describe "#enterprise_logo" do
    let(:enterprise) { double }

    context "when enterprise is nil" do
      it "returns nil" do
        expect(helper.enterprise_logo(nil)).to be_nil
      end
    end

    context "when logo is not variable" do
      let(:logo) { double(variable?: false) }

      before do
        allow(enterprise).to receive(:logo).and_return(logo)
      end

      it "returns nil" do
        expect(helper.enterprise_logo(enterprise)).to be_nil
      end
    end

    context "when logo is variable" do
      let(:logo) { double(variable?: true) }

      before do
        allow(enterprise).to receive(:logo).and_return(logo)
        allow(enterprise).to receive(:logo_url).with(:medium).and_return("http://example.com/logo.png")
      end

      it "returns an image tag with the logo" do
        result = helper.enterprise_logo(enterprise)

        expect(result).to include("img")
        expect(result).to include("http://example.com/logo.png")
        expect(result).to include('class="float-right"')
      end
    end
  end
end
