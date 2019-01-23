require "spec_helper"

# An inheritance bug made these specs fail.
# See config/initializers/spree.rb
shared_examples "taggable" do |parameter|
  it "uses the given parameter" do
    expect(subject.tag_list).to eq []
  end
end

module Spree
  describe PaymentMethod do
    it_behaves_like "taggable"
  end

  describe Gateway do
    it_behaves_like "taggable"
  end

  describe Gateway::PayPalExpress do
    it_behaves_like "taggable"
  end

  describe Gateway::StripeConnect do
    it_behaves_like "taggable"
  end
end
