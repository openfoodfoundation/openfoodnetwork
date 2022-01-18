# frozen_string_literal: true

require 'spec_helper'

describe UrlGenerator do
  subject { UrlGenerator }

  describe "#to_url" do
    it "converts to url-safe strings and removes unusable characters" do
      expect(subject.to_url("Top Cat!?")).to eq "top-cat"
    end

    it "handles accents" do
      expect(subject.to_url("Père Noël")).to eq "pere-noel"
    end

    it "handles transliteration of Chinese characters" do
      expect(subject.to_url("你好")).to eq "ni-hao"
    end
  end
end
