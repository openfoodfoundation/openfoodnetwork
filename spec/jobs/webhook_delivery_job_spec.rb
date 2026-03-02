# frozen_string_literal: true

RSpec.describe WebhookDeliveryJob do
  subject { WebhookDeliveryJob.new(url, event, data, at:) }
  let(:url) { 'https://test/endpoint' }
  let(:event) { 'order_cycle.opened' }
  let(:at) { 1.second.ago }
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
    freeze_time do
      expected_body = {
        id: /.+/,
        at: at.to_s,
        event:,
        data:,
      }

      subject.perform_now
      expect(a_request(:post, url).with(body: expected_body)).
        to have_been_made.once
    end
  end

  # Ensure responses from a local network aren't allowed, to prevent a user
  # seeing a private response or initiating an unauthorised action (SSRF).
  # Currently, we're not doing anything with responses. When we do, we should
  # update this to confirm the response isn't exposed.
  describe "server side request forgery" do
    describe "private addresses" do
      before(:all) do
        # Open port to await connections.
        # Will free port when process ends. Can't free it before.
        TCPServer.new(3001)
      end
      private_addresses = [
        "http://127.0.0.1:3001/all_the_secrets",
        "http://localhost:3001/all_the_secrets",
      ]

      private_addresses.each do |url|
        it "rejects private address #{url}" do
          expect {
            WebhookDeliveryJob.perform_now(url, event, data)
          }.to raise_error(PrivateAddressCheck::PrivateConnectionAttemptedError)
        end
      end
    end

    describe "redirects" do
      it "doesn't follow a redirect" do
        other_url = 'http://localhost/all_the_secrets'

        stub_request(:post, url).
          to_return(status: 302, headers: { 'Location' => other_url })
        stub_request(:any, other_url)

        expect {
          subject.perform_now
        }.to raise_error(StandardError, "302")

        expect(a_request(:any, other_url)).not_to have_been_made
      end
    end
  end

  # Exceptions are considered a job failure, which the job runner
  # (Sidekiq) and/or ActiveJob will handle and retry later.
  describe "failure" do
    it "raises error on server error" do
      stub_request(:post, url).to_return(status: [500, "Internal Server Error"])

      expect{ subject.perform_now }.to raise_error(StandardError, "500")
    end
  end
end
