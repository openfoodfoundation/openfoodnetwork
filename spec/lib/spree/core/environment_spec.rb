# frozen_string_literal: true

require 'spec_helper'

describe Spree::Core::Environment do
  # Our version doesn't add any features we could test.
  # So we just check that our file is loaded correctly.
  let(:our_file) { Rails.root.join("lib/spree/core/environment.rb").to_s }

  it "is defined in our code" do
    file = subject.method(:initialize).source_location.first
    expect(file).to eq our_file
  end

  it "used by Spree" do
    file = Spree::Core::Engine.config.spree.method(:initialize).source_location.first
    expect(file).to eq our_file
  end
end
