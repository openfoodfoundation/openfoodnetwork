module AdminHelper
  def have_admin_menu_item(menu_item_name)
    have_selector "ul[data-hook='admin_tabs'] li", text: menu_item_name
  end

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
