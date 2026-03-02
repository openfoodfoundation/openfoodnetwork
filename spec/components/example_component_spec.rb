# frozen_string_literal: true

RSpec.describe ExampleComponent, type: :component do
  it "displays the h1 with the given parameter" do
    render_inline(described_class.new(title: "Hello"))
    expect(page).to have_selector "h1", text: "Hello"
  end
end
