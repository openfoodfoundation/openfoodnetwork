# frozen_string_literal: true

RSpec.describe "admin/products_v3/_filters.html.haml" do
  helper Admin::ProductsHelper

  subject { render }

  let(:locals) do
    {
      spree_current_user:,
      search_term: "",
      allowed_producers: [],
      producer_id: nil,
      category_id: nil,
    }
  end
  let(:spree_current_user) { build(:enterprise_user) }

  it "shows the producer filter with the default option initially" do
    allow(view).to receive_messages locals.merge(
      allowed_producers: [
        instance_double(Enterprise, id: 1),
        instance_double(Enterprise, id: 2),
      ],
    )

    is_expected.to have_content "Enterprises"
    is_expected.to have_select "producer_id", options: [
      "All enterprises"
    ], selected: nil
  end

  it "doesn't show the producer filter when there's only one option" do
    allow(view).to receive_messages locals.merge(
      allowed_producers: [
        instance_double(Enterprise, id: 1),
      ],
    )

    is_expected.not_to have_content "Producers"
    is_expected.not_to have_select "producer_id"
  end
end
