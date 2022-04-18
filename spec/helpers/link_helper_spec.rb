# frozen_string_literal: true

require 'spec_helper'

describe LinkHelper, type: :helper do
  describe "ext_url" do
    it "adds prefix if missing" do
      expect(helper.ext_url("http://example.com/", "http://example.com/bla")).to eq("http://example.com/bla")
      expect(helper.ext_url("http://example.com/", "bla")).to eq("http://example.com/bla")
    end
  end
end
