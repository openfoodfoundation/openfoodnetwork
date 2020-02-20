Spree::Core::ControllerHelpers::Auth.class_eval do
  def require_login_then_redirect_to(url)
    redirect_to main_app.root_path(anchor: "login?after_login=#{url}")
  end
end
