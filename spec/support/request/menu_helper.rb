module MenuHelper
  def open_login_modal
    find("a", text: "LOG IN").click
  end

  def have_login_modal
    have_selector ".login-modal" 
  end
end
