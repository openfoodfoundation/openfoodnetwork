module UIComponentHelper

  def browse_as_medium
    page.driver.resize(1024, 768)
  end

  def browse_as_large
    page.driver.resize(1280, 800)
  end

  def open_login_modal
    find("a", text: "LOG IN").click
  end

  def open_off_canvas
    find("a.left-off-canvas-toggle").click
  end

  def have_login_modal
    have_selector ".login-modal" 
  end
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
