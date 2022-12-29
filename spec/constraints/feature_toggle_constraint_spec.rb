# frozen_string_literal: true

require 'spec_helper'

describe FeatureToggleConstraint do
  subject { described_class.new("baking") }
  let(:request) { double(env: env) }
  let(:env) { {} }

  it "constraints an unknown feature" do
    expect(subject.matches?(request)).to eq false
  end

  it "allows an activated feature" do
    Flipper.enable("baking")

    expect(subject.matches?(request)).to eq true
  end

  it "negates results" do
    subject = described_class.new("baking", negate: true)

    expect(subject.matches?(request)).to eq true

    Flipper.enable("baking")
    expect(subject.matches?(request)).to eq false
  end
end
