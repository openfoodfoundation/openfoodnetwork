module UIComponentHelper
  def open_active_table_row
    find("hub:first-child .active_table_row:first-child").click()
  end
end
