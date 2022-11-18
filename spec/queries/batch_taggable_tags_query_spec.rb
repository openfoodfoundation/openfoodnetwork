# frozen_string_literal: true

require 'spec_helper'

describe BatchTaggableTagsQuery do
  it "fetches tags for multiple models in one query" do
    customer_i = create(:customer, tag_list: "member,volunteer")
    customer_ii = create(:customer, tag_list: "member")
    customer_iii = create(:customer, tag_list: nil)

    tags = BatchTaggableTagsQuery.call(
      Customer.where(id: [customer_i, customer_ii, customer_iii])
    )
    expect(tags).to eq(
      {
        customer_i.id => ["member", "volunteer"],
        customer_ii.id => ["member"],
      }
    )
  end
end
