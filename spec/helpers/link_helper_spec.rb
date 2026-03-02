# frozen_string_literal: true

RSpec.describe LinkHelper do
  describe "ext_url" do
    it "adds prefix if missing" do
      expect(helper.ext_url("http://example.com/", "http://example.com/bla")).to eq("http://example.com/bla")
      expect(helper.ext_url("http://example.com/", "bla")).to eq("http://example.com/bla")
    end
  end

  describe "link_to_or_disabled" do
    it "behaves like the standard :link_to method e.g. it accepts the same arguments and accepts
        blocks, etc." do
      expect(helper.link_to_or_disabled("Go", "http://example.com/")).to eq(
        "<a href=\"http://example.com/\">Go</a>"
      )
      expect(helper.link_to_or_disabled("Go", "http://example.com/", class: "button")).to eq(
        "<a class=\"button\" href=\"http://example.com/\">Go</a>"
      )
      expect(helper.link_to_or_disabled("http://example.com/") { "Go" }).to eq(
        "<a href=\"http://example.com/\">Go</a>"
      )
    end

    it "accepts an additional boolean :disabled argument, which if true renders a disabled link" do
      expect(helper.link_to_or_disabled("Go", "http://example.com/", disabled: true)).to eq(
        "<a aria-disabled=\"true\" class=\"disabled\" role=\"link\">Go</a>"
      )
    end
  end
end
