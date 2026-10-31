# frozen_string_literal: true

RSpec.describe OrderingPickerComponent, type: :component do
  subject(:picker) {
    described_class.new(
      name: "order", id: "order", options: [["Fruit", 1], ["Veg", 2]], value: "2,1",
      placeholder: "Category", readonly: true, data: { test: "value" },
    )
  }

  it "submits the ordered values as text" do
    render_inline(picker)

    expect(page).to have_field "Category", with: "2,1", type: "text", readonly: true
  end

  it "sets up TomSelect with the options" do
    render_inline(picker)

    input = page.find_field("Category")
    expect(input["data-controller"]).to eq "tom-select"
    expect(input["data-test"]).to eq "value"

    tom_select_options = JSON.parse(input["data-tom-select-options-value"])
    expect(tom_select_options["options"]).to eq [
      { "label" => "Fruit", "value" => "1" },
      { "label" => "Veg", "value" => "2" },
    ]
    expect(tom_select_options["plugins"]).to include "drag_drop"
  end
end
