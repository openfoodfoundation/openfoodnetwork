# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConnectAppJob, type: :job, vcr: true do
  subject { ConnectAppJob.new(app, token) }

  let(:app) { ConnectedApp.create!(enterprise: ) }
  let(:enterprise) { create(:enterprise) }
  let(:token) { enterprise.owner.spree_api_key }

  before { enterprise.owner.generate_api_key }

  it "stores connection data on the app" do
    subject.perform_now

    expect(app.data).to eq({ "link" => "https://example.net/edit" })
  end
end
