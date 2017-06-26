require 'spec_helper'

describe Api::VariantSerializer do
  let(:serializer) { Api::VariantSerializer.new variant }
  let(:variant) { create(:variant) }


  it "serializes a variant" do
    expect(serializer.to_json).to match variant.id.to_s
  end


end
