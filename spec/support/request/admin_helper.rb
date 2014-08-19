module AdminHelper
  def have_admin_menu_item(menu_item_name)
    have_selector "ul[data-hook='admin_tabs'] li", text: menu_item_name
  end
end
