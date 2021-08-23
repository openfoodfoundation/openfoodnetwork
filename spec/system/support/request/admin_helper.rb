# frozen_string_literal: true

module AdminHelper
  def toggle_columns(*labels)
    # open dropdown
    find("div#columns-dropdown", text: "COLUMNS").click

    labels.each do |label|
      find("div#columns-dropdown div.menu div.menu_item", text: label).click
    end

    # close dropdown
    find("div#columns-dropdown", text: "COLUMNS").click
  end
end
