# frozen_string_literal: true

RSpec.describe PaypalRest::Result do
  it "exposes success and failure predicates" do
    expect(described_class.new(success: true)).to be_success
    expect(described_class.new(success: true)).not_to be_failure
    expect(described_class.new(success: false)).to be_failure
  end

  it "stringifies to its error message" do
    result = described_class.new(success: false, error_message: 'Order expired')

    expect(result.to_s).to eq('Order expired')
  end
end
