# frozen_string_literal: true

require 'spec_helper'

describe WebhookDeliveryJob do
  subject { WebhookDeliveryJob.new(url, event, data) }
  let(:url) { 'https://test/endpoint' }
  let(:event) { 'order_cycle.opened' }
  let(:data) {
    {
      order_cycle_id: 123, name: "Order cycle 1", open_at: 1.minute.ago.to_s, tags: ["tag1", "tag2"]
    }
  }

  before do
    stub_request(:post, url)
  end

  it "sends a request to specified url" do
    subject.perform_now
    expect(a_request(:post, url)).to have_been_made.once
  end

  it "delivers a payload" do
    Timecop.freeze(Time.zone.now) do
      expected_body = {
        id: /.+/,
        at: Time.zone.now.to_s,
        event: event,
        data: data,
      }

      subject.perform_now
      expect(a_request(:post, url).with(body: expected_body)).
        to have_been_made.once
    end
  end

  # To be implemented in following commits
  pending "can't access local secrets" # see https://medium.com/in-the-weeds/all-about-paperclips-cve-2017-0889-server-side-request-forgery-ssrf-vulnerability-8cb2b1c96fe8

  describe "retrying" do
    pending "doesn't retry on internal failure"
    pending "retries after external failure"
    pending "stops retrying after a while"
  end
end
