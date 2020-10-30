# frozen_string_literal: true

require 'spec_helper'

describe ActionDispatch::Request do
  it "strips nils from arrays" do
    expect(parse_query_parameters('key[]=value&key[]')).to eq({ "key" => ["value"] })
  end

  it "strips nils from nested arrays" do
    expect(
      parse_query_parameters('key1[key2][]=value&key1[key2][]')
    ).to eq({ "key1" => { "key2" => ["value"] } })
  end

  it "doesn't convert an empty array to nil" do
    expect(parse_query_parameters('key[]')).to eq({ "key" => [] })
  end

  private

  def parse_query_parameters(query_parameters)
    ActionDispatch::Request.new("QUERY_STRING" => query_parameters).query_parameters
  end
end
