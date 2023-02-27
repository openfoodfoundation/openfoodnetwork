# frozen_string_literal: true

module UIComponentHelper
  def browse_as_medium
    Capybara.current_session.current_window
      .resize_to(1024, 768)
  end

  def browse_as_large
    Capybara.current_session.current_window
      .resize_to(1280, 800)
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
    page.find("a", text: enterprise.name).click
  end

  def modal_should_be_open_for(object)
    within ".reveal-modal" do
      expect(page).to have_content object.name
    end
  end

  def close_modal
    find("a.close-reveal-modal").click
  end

  def have_reset_password
    have_content "An email with instructions on resetting your password has been sent!"
  end

  def have_in_cart(name)
    toggle_cart
    within ".cart-sidebar" do
      have_content name
    end
  end

  def toggle_cart
    page.find("#cart").click
    sleep 0.3 # Allow 300ms for sidebar animation to finish
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

  def expand_active_table_node(name)
    page.find(".active_table_node", text: name).click
  end

  def follow_active_table_node(name)
    expand_active_table_node(name)
    page.find(".active_table_node a", text: name.to_s).click
  end

  def fill_in_using_keyboard
    page.find('#spree_user_email').send_keys(user.email, :tab, user.password, :tab, :space)
    expect(page.find('#spree_user_remember_me')).to be_checked
    page.find('#spree_user_remember_me').send_keys(:tab, :enter)
  end
end
