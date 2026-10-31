# frozen_string_literal: true

RSpec.describe SettingsRowComponent, type: :component do
  it "displays the title, description and content" do
    render_inline(described_class.new(id: "row", title: "Title", description: "Description")) do
      "Options"
    end

    expect(page).to have_selector "#row_title", text: "Title"
    expect(page).to have_selector ".settings-row-description", text: "Description"
    expect(page).to have_selector "[role=group][aria-labelledby=row_title]", text: "Options"
  end

  it "hides a blank description" do
    render_inline(described_class.new(id: "row", title: "Title", description: nil))

    expect(page).not_to have_selector ".settings-row-description"
  end

  it "passes other options to the row element" do
    render_inline(described_class.new(id: "row", title: "Title", data: { test: "value" }))

    expect(page).to have_selector "#row.settings-row[data-test=value]"
  end
end
