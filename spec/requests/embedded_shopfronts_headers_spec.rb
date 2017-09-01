require 'spec_helper'

describe "setting response headers for embedded shopfronts", type: :request do
  include AuthenticationWorkflow

  let(:enterprise) { create(:distributor_enterprise) }
  let(:user) { enterprise.owner }

  before do
    quick_login_as(user)
  end

  context "with embedded shopfront disabled" do
    before do
      Spree::Config[:enable_embedded_shopfronts] = false
    end

    it "disables iframes by default" do
      get shops_path
      expect(response.status).to be 200
      expect(response.headers['X-Frame-Options']).to eq 'DENY'
      expect(response.headers['Content-Security-Policy']).to eq "frame-ancestors 'none'"
    end
  end

  context "with embedded shopfronts enabled" do
    before do
      Spree::Config[:enable_embedded_shopfronts] = true
    end

    context "but no whitelist" do
      before do
        Spree::Config[:embedded_shopfronts_whitelist] = ""
      end

      it "disables iframes" do
        get shops_path
        expect(response.status).to be 200
        expect(response.headers['X-Frame-Options']).to eq 'DENY'
        expect(response.headers['Content-Security-Policy']).to eq "frame-ancestors 'none'"
      end
    end

    context "with a valid whitelist" do
      before do
        Spree::Config[:embedded_shopfronts_whitelist] = "test.com"
      end

      it "allows iframes on certain pages when enabled in configuration" do
        get shops_path
        expect(response.status).to be 200
        expect(response.headers['X-Frame-Options']).to be_nil
        expect(response.headers['Content-Security-Policy']).to eq "frame-ancestors test.com"

        get spree.admin_path
        expect(response.status).to be 200
        expect(response.headers['X-Frame-Options']).to eq 'DENY'
        expect(response.headers['Content-Security-Policy']).to eq "frame-ancestors 'none'"
      end
    end
  end
end
