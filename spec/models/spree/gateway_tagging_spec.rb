# frozen_string_literal: true

require "spec_helper"

# We extended Spree::PaymentMethod to be taggable. Unfortunately, an inheritance
# bug prevented the taggable code to be passed on to the descendants of
# PaymentMethod. We fixed that in config/initializers/spree.rb.
#
# This spec tests several descendants for their taggability. The tests are in
# a separate file, because they cover one aspect of several classes.
shared_examples "taggable" do |expected_taggable_type|
  it "provides a tag list" do
    expect(subject.tag_list).to eq []
  end

  it "stores tags for the root taggable type" do
    subject.tag_list.add("one")
    subject.save!

    expect(subject.taggings.last.taggable_type).to eq expected_taggable_type
  end
end

module Spree
  describe "PaymentMethod and descendants" do
    let(:shop) { create(:enterprise) }
    let(:valid_subject) do
      # Supply required parameters so that it can be saved to attach taggings.
      described_class.new(
        name: "Some payment method",
        distributor_ids: [shop.id]
      )
    end
    subject { valid_subject }

    describe PaymentMethod do
      it_behaves_like "taggable", "Spree::PaymentMethod"
    end

    describe Gateway do
      it_behaves_like "taggable", "Spree::PaymentMethod"
    end

    describe Gateway::PayPalExpress do
      it_behaves_like "taggable", "Spree::PaymentMethod"
    end

    describe Gateway::StripeSCA do
      subject do
        # StripeSCA needs an owner to be valid.
        valid_subject.tap { |m| m.preferred_enterprise_id = shop.id }
      end

      it_behaves_like "taggable", "Spree::PaymentMethod"
    end
  end
end
