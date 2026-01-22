# frozen_string_literal: true

RSpec.describe VerticalEllipsisMenuComponent, type: :component do
  it "displays the included links" do
    content = "<a href>Edit</a>"
    render_inline(described_class.new.with_content(content.html_safe))

    expect(page).to have_selector "a", text: "Edit"
  end
end
