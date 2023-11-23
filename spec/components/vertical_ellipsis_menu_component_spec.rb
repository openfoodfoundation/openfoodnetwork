# frozen_string_literal: true

require "spec_helper"

describe VerticalEllipsisMenuComponent, type: :component do
  it "displays the included links" do
    content = "<a href>Edit</a>"
    render_inline(VerticalEllipsisMenuComponent.new.with_content(content.html_safe))

    expect(page).to have_selector "a", text: "Edit"
  end
end
