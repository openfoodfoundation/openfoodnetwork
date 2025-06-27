# frozen_string_literal: true

require 'spec_helper'
require 'spree/core/fake_method'

# Just checking that undercover recognises this.
RSpec.describe Spree::Core::FakeMethod do
  it do
    expect(subject.square(3)).to eq 9
  end
end
