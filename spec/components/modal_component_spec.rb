# frozen_string_literal: true

RSpec.describe ModalComponent, type: :component do
  it "renders default 'data-action' and 'data-controller'" do
    render_inline(described_class.new(id: "test-id"))

    expect(page).to have_selector "#test-id"
    expect(page).to have_selector '[data-controller="modal"]'
    expect(page).to have_selector '[data-action="keyup@document->modal#closeIfEscapeKey"]'
  end

  it "accepts html attributes options" do
    render_inline(described_class.new(id: "test-id", 'data-test': "some data"))

    expect(page).to have_selector "#test-id"
    expect(page).to have_selector '[data-test="some data"]'
  end

  it "merges 'data-controller' attribute when present in options" do
    render_inline(described_class.new(id: "test-id", 'data-controller': "other-controller"))

    expect(page).to have_selector "#test-id"
    expect(page).to have_selector '[data-controller="modal other-controller"]'
  end

  it "merges 'data-action' attribute when present in options" do
    render_inline(described_class.new(id: "test-id", 'data-action': "click->other-controller#test"))

    expect(page).to have_selector "#test-id"
    expect(page).to have_selector(
      '[data-action="keyup@document->modal#closeIfEscapeKey click->other-controller#test"]'
    )
  end
end
