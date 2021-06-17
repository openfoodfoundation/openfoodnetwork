# frozen_string_literal: true

require "spec_helper"

describe "DistributorTitle tests", type: :component do
  it "displays distributor title with its name" do
    render_inline(DistributorTitleComponent.new(name: "Freddy's Farm Shop")) {}
    expect(page).to have_selector "h3", text: "Freddy's Farm Shop"
  end
end
