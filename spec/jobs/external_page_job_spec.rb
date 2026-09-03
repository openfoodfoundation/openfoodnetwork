# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExternalPageJob do
  let(:url) { "https://cms.example.com/home/" }

  it "refreshes the configured home page" do
    ContentConfig.home_page_url = url
    stub_request(:get, url).
      to_return(body: '<html><body><div class="entry-content">Hi</div></body></html>')

    described_class.perform_now

    expect(CachedExternalPage.fetch(url)[:content]).to include "Hi"
  end

  it "does nothing without a configured page" do
    ContentConfig.home_page_url = ""

    expect { subject.perform_now }.not_to raise_error
  end

  it "reports errors instead of failing the job" do
    stub_request(:get, url).to_timeout

    expect(Bugsnag).to receive(:notify).with(instance_of(Faraday::ConnectionFailed))

    described_class.perform_now(url)
  end
end
