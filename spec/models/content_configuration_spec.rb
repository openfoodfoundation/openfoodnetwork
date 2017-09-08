require 'spec_helper'

describe ContentConfiguration do
  describe "default logos and home_hero" do
    it "sets a default url with existing image" do
      expect(image_exist?(ContentConfig.logo.options[:default_url])).to be true
      expect(image_exist?(ContentConfig.logo_mobile_svg.options[:default_url])).to be true
      expect(image_exist?(ContentConfig.home_hero.options[:default_url])).to be true
      expect(image_exist?(ContentConfig.footer_logo.options[:default_url])).to be true
    end

    def image_exist?(default_url)
      image_path = default_url.gsub(/\/assets\//,'/assets/images/')
      File.exist?(File.join(Rails.root, 'app', image_path))
    end
  end
end
