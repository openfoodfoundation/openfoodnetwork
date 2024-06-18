# frozen_string_literal: true

module AdminHelper
  def toggle_columns(*labels)
    # open dropdown
    columns_dropdown = ofn_drop_down("Columns")
    columns_dropdown.click

    within columns_dropdown do
      labels.each do |label|
        # Convert label to case-insensitive regexp if not one already
        label = /#{label}/i unless label.is_a?(Regexp)

        find("div.menu div.menu_item", text: /#{label}/i).click
      end
    end

    # close dropdown
    columns_dropdown.click
  end

  def ofn_drop_down(label)
    find(".ofn-drop-down", text: /#{label}/i)
  end
end
