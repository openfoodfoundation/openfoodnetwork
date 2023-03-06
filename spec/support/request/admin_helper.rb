# frozen_string_literal: true

module AdminHelper
  def toggle_columns(*labels)
    # open dropdown
    # case insensitive search for "Columns" text
    find("div#columns-dropdown", text: /columns/i).click

    within "div#columns-dropdown" do
      labels.each do |label|
        # Convert label to case-insensitive regexp if not one already
        label = /#{label}/i unless label.is_a?(Regexp)

        find("div.menu div.menu_item", text: /#{label}/i).click
      end
    end

    # close dropdown
    find("div#columns-dropdown", text: /columns/i).click
  end
end
