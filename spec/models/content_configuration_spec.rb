# frozen_string_literal: true

require 'spec_helper'

describe ContentConfiguration do
  describe "default logos and home_hero" do
    it "sets a default url with existing image" do
      expect(image_exist?(ContentConfig.url_for(:logo))).to be true
      expect(image_exist?(ContentConfig.url_for(:logo_mobile_svg))).to be true
      expect(image_exist?(ContentConfig.url_for(:home_hero))).to be true
      expect(image_exist?(ContentConfig.url_for(:footer_logo))).to be true
    end

    def image_exist?(default_url)
      File.exist?(File.join(Rails.root, 'public', default_url))
    end
  end
end
