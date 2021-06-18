# frozen_string_literal: true

require "spec_helper"

describe "ExampleComponent tests", type: :component do
  it "displays the h1 with the given parameter" do
    render_inline(ExampleComponent.new(title: "Hello")) {}
    expect(page).to have_selector "h1", text: "Hello"
  end
end
