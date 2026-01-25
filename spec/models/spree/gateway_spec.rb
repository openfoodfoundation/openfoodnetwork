# frozen_string_literal: true

RSpec.describe Spree::Gateway do
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
    gateway = test_gateway.new
    expect(gateway.provider).to receive(:imaginary_method).with('foo')
    gateway.imaginary_method('foo')
  end
end
