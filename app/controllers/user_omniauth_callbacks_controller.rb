class UserOmniauthCallbacksController < Devise::OmniauthCallbacksController
    def facebook
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = Spree::User.find_from_facebook(request.env["omniauth.auth"])
    if @user
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      redirect_to request.referer + "#/signup"
    end
  end

  def failure
    redirect_to root_path
  end
end