require 'spec_helper'

describe GroupsHelper, type: :helper do
   describe "ext_url" do
     it "adds prefix if missing" do
       expect(helper.ext_url("http://example.com/", "http://example.com/bla")).to eq("http://example.com/bla")
       expect(helper.ext_url("http://example.com/", "bla")).to eq("http://example.com/bla")
     end
   end
   describe "strip_url" do
     it "removes http(s)://" do
       expect(helper.strip_url("http://example.com/")).to eq("example.com/")
       expect(helper.strip_url("https://example.com/")).to eq("example.com/")
       expect(helper.strip_url("example.com")).to eq("example.com")
     end
   end
end
