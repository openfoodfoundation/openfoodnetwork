require 'spec_helper'

describe Spree::AppConfiguration do
  context "when testing using the ConfigStubber" do
    it "provides access to default values" do
      expect(Spree::Config.site_name).to eq "Spree Demo Site"
      expect(Spree::Config.site_url).to eq "demo.spreecommerce.com"
      expect(Spree::Config.stripe_connect_enabled).to be false
      expect(Spree::Config.enable_embedded_shopfronts).to be false
    end

    it "allows config settings to be set in a variety of ways" do
      Spree::Config.set(site_name: "name1")
      expect(Spree::Config.get(:site_name)).to eq "name1"
      expect(Spree::Config[:site_name]).to eq "name1"
      expect(Spree::Config.site_name).to eq "name1"
      Spree::Config[:site_name] = "name2"
      expect(Spree::Config.get(:site_name)).to eq "name2"
      expect(Spree::Config[:site_name]).to eq "name2"
      expect(Spree::Config.site_name).to eq "name2"
      Spree::Config.site_name = "name3"
      expect(Spree::Config.get(:site_name)).to eq "name3"
      expect(Spree::Config[:site_name]).to eq "name3"
      expect(Spree::Config.site_name).to eq "name3"
    end

    it "prevents Config settings from being cached" do
      expect(%w(name1, name2, name3)).to_not include Spree::Config.get(:site_name)
      expect(%w(name1, name2, name3)).to_not include Spree::Config[:site_name]
      expect(%w(name1, name2, name3)).to_not include Spree::Config.site_name
    end
  end
end
