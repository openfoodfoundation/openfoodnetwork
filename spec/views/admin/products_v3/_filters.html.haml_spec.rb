# frozen_string_literal: true

RSpec.describe "admin/products_v3/_filters.html.haml" do
  helper Admin::ProductsHelper

  subject { render }

  let(:locals) do
    {
      spree_current_user:,
      search_term: "",
      producer_options: [],
      producer_id: nil,
      category_options: [],
      category_id: nil,
    }
  end
  let(:spree_current_user) { build(:enterprise_user) }

  it "shows the producer filter when there are options" do
    allow(view).to receive_messages locals.merge(
      producer_options: [
        ["Ada's Apples", 1],
        ["Ben's Bananas", 2],
      ],
    )

    is_expected.to have_content "Producers"
    is_expected.to have_select "producer_id", options: [
      "All producers",
      "Ada's Apples",
      "Ben's Bananas",
    ], selected: nil
  end

  it "doesn't show the producer filter when there's only one option" do
    allow(view).to receive_messages locals.merge(
      producer_options: [
        ["Ada's Apples", 1],
      ],
    )

    is_expected.not_to have_content "Producers"
    is_expected.not_to have_select "producer_id"
  end
end
