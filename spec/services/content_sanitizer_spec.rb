# frozen_string_literal: true

require 'spec_helper'

describe ContentSanitizer do
  let(:service) { described_class.new }

  context "#strip_content" do
    it "strips disallowed tags" do
      expect(service.strip_content("I'm friendly!<script>alert('hello! I'm malicious');</script>"))
        .to eq("I'm friendly!")
    end

    it "replaces spaces" do
      expect(service.strip_content("swiss&nbsp;chard")).to eq("swiss chard")
    end

    it "replaces ampersands" do
      expect(service.strip_content("pb &amp; j")).to eq("pb & j")
    end

    it "replaces double escaped ampersands" do
      expect(service.strip_content("pb &amp;amp; j")).to eq("pb & j")
    end

    it "echos nil if given nil" do
      expect(service.strip_content(nil)).to be(nil)
    end
  end

  context "#sanitize_content" do
    it "leaves bold tags" do
      bold = "<b>I'm bold</b>"
      expect(service.sanitize_content(bold)).to eq(bold)
    end

    it "leaves links intact" do
      link = "<a href=\"https://foo.com\">Bar</a>"
      expect(service.sanitize_content(link)).to eq(link)
    end

    it "replaces spaces" do
      expect(service.sanitize_content("swiss&nbsp;chard")).to eq("swiss chard")
    end

    it "replaces ampersands" do
      expect(service.sanitize_content("pb &amp; j")).to eq("pb & j")
    end

    it "replaces double escaped ampersands" do
      expect(service.sanitize_content("pb &amp;amp; j")).to eq("pb & j")
    end

    it "echos nil if given nil" do
      expect(service.sanitize_content(nil)).to be(nil)
    end

    it "removes empty <p> tags and keeps non-empty ones" do
      expect(service.sanitize_content("<p> </p><p></p><p><b></b><p>hello</p><p></p><p>world!</p>"))
        .to eq("<p>hello</p><p>world!</p>")
    end
  end
end
