# frozen_string_literal: true

RSpec.describe AdminTooltipComponent, type: :component do
  it "displays the tooltip link" do
    render_inline(described_class.new(text: "Tooltip description", link_text: "Hover here"))

    expect(page).to have_selector "a", text: "Hover here"
  end

  describe "text" do
    it "displays the tooltip text" do
      render_inline(described_class.new(text: "Tooltip description", link_text: "Hover here"))

      expect(page).to have_selector ".tooltip", text: "Tooltip description"
    end

    it "sanitizes the tooltip text" do
      render_inline(described_class.new( text: "Tooltip <span>description</span>",
                                         link_text: "Hover here"))

      expect(page).to have_selector ".tooltip", text: "Tooltip description"
    end
  end

  describe "placement" do
    it "uses top as default" do
      render_inline(described_class.new(text: "Tooltip <span>description</span>",
                                        link_text: "Hover here"))

      expect(page).to have_selector '[data-tooltip-placement-value="top"]'
    end

    it "uses the given placement" do
      render_inline(described_class.new(text: "Tooltip <span>description</span>",
                                        link_text: "Hover here", placement: "left"))
      expect(page).to have_selector '[data-tooltip-placement-value="left"]'
    end
  end

  it "adds the correct link" do
    render_inline(described_class.new(text: "Tooltip description", link_text: "Hover here",
                                      link: "www.ofn.com"))

    expect(page).to have_selector '[href="www.ofn.com"]'
  end

  it "adds the correct link_class" do
    render_inline(described_class.new(text: "Tooltip description", link_text: "Hover here",
                                      link_class: "pretty"))
    expect(page).to have_selector 'a[class="pretty"]'
  end
end
