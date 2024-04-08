# frozen_string_literal: true

require 'spec_helper'

describe Spree::Gateway do
  it "passes through all arguments on a method_missing call" do
    gateway = TestGateway.new
    expect(gateway.provider).to receive(:imaginary_method).with('foo')
    gateway.imaginary_method('foo')
  end
end

class Provider
  def initialize(options); end

  def imaginary_method; end
end

class TestGateway < Spree::Gateway
  def provider_class
    Provider
  end
end
