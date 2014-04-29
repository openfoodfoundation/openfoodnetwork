module UIComponentHelper
  def open_active_table_row
    find("hub:first-child .active_table_row:first-child").click()
  end

  def expand_active_table_node(name)
    find(".active_table_node", text: name).click
  end
  
  def follow_active_table_node(name)
    expand_active_table_node(name)
    find(".active_table_node a", text: "Shop at #{name}").click
  end
end
