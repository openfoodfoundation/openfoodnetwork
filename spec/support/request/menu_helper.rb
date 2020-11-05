# frozen_string_literal: true

module MenuHelper
  def open_login_modal
    find("a", text: "Log in").click
  end

  def have_login_modal
    have_selector ".login-modal"
  end
end
