# frozen_string_literal: true

require 'spec_helper'

describe 'current Stripe gem version vs Stripe VCR cassete version' do
  let(:stripe_v_gemfile) { Gem.loaded_specs["stripe"].version.to_s }

  # stripe_v_vcr_tests should correspond the versions from the recorded
  # VCR cassetes; we'd need to (WIP):
  # i) add the version to the file name of the VCR cassetes
  # ii) fetch the version from the file name, for the assertion below
  let(:stripe_v_vcr_tests) { "10.0.0" } # WIP

  it "verifies stripe version is up to date" do
    # This now passes as the version is manually added on stripe_v_vcr_tests
    expect(stripe_v_gemfile).to eq stripe_v_vcr_tests
  end
end
