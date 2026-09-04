# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CachedExternalPage do
  let(:url) { "https://cms.example.com/home/" }
  let(:html) { '<html><body><div class="entry-content"><p>Hello</p></div></body></html>' }

  before { Rails.cache.clear }

  describe ".fetch" do
    it "returns nothing without a URL" do
      expect(described_class.fetch("")).to be_nil
    end

    it "doesn't wait for the CMS but requests the content in the background" do
      stub_request(:get, url) # would raise if called

      expect { described_class.fetch(url) }.to have_enqueued_job(ExternalPageJob).with(url)
      expect(WebMock).not_to have_requested(:get, url)
    end

    it "requests the content only once while a refresh is pending" do
      described_class.fetch(url)

      expect { described_class.fetch(url) }.not_to have_enqueued_job(ExternalPageJob)
    end

    it "returns the cached content" do
      stub_request(:get, url).to_return(body: html)
      described_class.refresh(url)

      page = described_class.fetch(url)

      expect(page[:content]).to include "<p>Hello</p>"
      expect(page[:fetched_at]).to be_within(1.minute).of(Time.zone.now)
    end

    it "serves old content while refreshing it in the background" do
      stub_request(:get, url).to_return(body: html)
      travel_to(1.hour.ago) { described_class.refresh(url) }

      expect { expect(described_class.fetch(url)[:content]).to include "<p>Hello</p>" }.
        to have_enqueued_job(ExternalPageJob).with(url)
    end
  end

  describe ".refresh" do
    it "doesn't cache an empty page" do
      stub_request(:get, url).to_return(body: "")

      expect { described_class.refresh(url) }.to raise_error(/No content/)
      expect(described_class.fetch(url)).to be_nil
    end
  end
end
