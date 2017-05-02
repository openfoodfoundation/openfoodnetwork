module UIComponentHelper

  def browse_as_medium
    page.driver.resize(1024, 768)
  end

  def browse_as_large
    page.driver.resize(1280, 800)
  end

  def click_login_button
    click_button "Login"
  end

  def click_signup_button
    click_button "Sign up now"
  end

  def click_reset_password_button
    click_button "Reset password"
  end

  def select_login_tab(text)
    within ".login-modal" do
      page.find("a", text: text).click
    end
    sleep 0.2
  end

  def open_login_modal
    page.find("a", text: "Login").click
  end

  def open_off_canvas
    page.find("a.left-off-canvas-toggle").click
  end

  def have_login_modal
    have_selector ".login-modal"
  end

  def open_product_modal(product)
    page.find("a", text: product.name).click
  end

  def open_enterprise_modal(enterprise)
    page.find("a", text: enterprise.name).trigger "click"
  end

  def modal_should_be_open_for(object)
    within ".reveal-modal" do
      page.should have_content object.name
    end
  end

  def have_reset_password
    have_content "An email with instructions on resetting your password has been sent!"
  end

  def have_in_cart name
    show_cart
    within "li.cart" do
      have_content name
    end
  end

  def show_cart
    page.find("#cart").click
  end

  def cart_dirty
    page.find("span.cart-span")[:class].include? 'pure-dirty'
  end

  def wait_for_ajax
    counter = 0
    while page.execute_script("return $.active").to_i > 0
      counter += 1
      sleep(0.1)
      raise "AJAX request took longer than 5 seconds." if counter >= 50
    end
  end

  def be_logged_in_as(user_or_email)
    if user_or_email.is_a? Spree::User
      have_content user_or_email.email
    else
      have_content user_or_email
    end
  end

  def be_logged_out
    have_content "Log in"
  end

  def open_active_table_row
    page.find("hub:first-child .active_table_row:first-child").click()
  end

  def expand_active_table_node(name)
    page.find(".active_table_node", text: name).click
  end

  def follow_active_table_node(name)
    expand_active_table_node(name)
    page.find(".active_table_node a", text: "#{name}").click
  end
end
