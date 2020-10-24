require 'spec_helper'

describe ActionDispatch::Request do
  it "strips nils from arrays" do
    assert_parses({ "key" => ["value"] }, 'key[]=value&key[]')
    assert_parses({ "key1" => { "key2" => ["value"] } }, 'key1[key2][]=value&key1[key2][]')
  end

  it "doesn't convert an empty array to nil" do
    assert_parses({ "key" => [] }, 'key[]')
  end

  private

  def assert_parses(expected, actual)
    assert_equal expected, ActionDispatch::Request.new('QUERY_STRING' => actual).query_parameters
  end
end
