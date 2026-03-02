# frozen_string_literal: true

RSpec.describe Spree::Gateway do
  subject(:gateway) { test_gateway.new }
  let(:test_gateway) do
    Class.new(Spree::Gateway) do
      def provider_class
        Class.new do
          def initialize(*); end

          def imaginary_method; end
        end
      end
    end
  end

  it "passes through all arguments on a method_missing call" do
    expect(Rails.env).to receive(:local?).and_return(false)
    expect(gateway.provider).to receive(:imaginary_method).with('foo')
    gateway.imaginary_method('foo')
  end

  it "raises an error in test env" do
    expect { gateway.imaginary_method('foo') }.to raise_error StandardError
  end
end
