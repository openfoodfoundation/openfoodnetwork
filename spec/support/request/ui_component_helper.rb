module UIComponentHelper

  def browse_as_medium
    page.driver.resize(1024, 768)
  end

  def browse_as_large
    page.driver.resize(1280, 800)
  end

  def click_login_button
    click_button "Log in"
  end

  def click_signup_button
    click_button "Sign up now"
  end

  def click_reset_password_button
    click_button "Reset password"
  end

  def select_login_tab(text)
    within ".login-modal" do
      find("a", text: text).click
    end
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

  def have_reset_password
    have_content "An email with instructions on resetting your password has been sent!"
  end

  def be_logged_in_as(user_or_email)
    if user_or_email.is_a? Spree::User
      have_content user_or_email.email
    else
      have_content user_or_email
    end
  end

  def be_logged_out
    have_content "LOG IN"
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
