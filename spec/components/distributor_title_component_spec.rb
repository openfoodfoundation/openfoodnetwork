# frozen_string_literal: true

RSpec.describe DistributorTitleComponent, type: :component do
  it "displays distributor title with its name" do
    render_inline(described_class.new(name: "Freddy's Farm Shop"))
    expect(page).to have_selector "h3", text: "Freddy's Farm Shop"
  end
end
