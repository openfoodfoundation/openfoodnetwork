Spree::BaseController.class_eval do
  def spree_login_path
    spree.login_path
  end

  def spree_signup_path
    spree.signup_path
  end

  def spree_logout_path
    spree.destroy_spree_user_session_path
  end

  def spree_current_user
    current_spree_user
  end
end

