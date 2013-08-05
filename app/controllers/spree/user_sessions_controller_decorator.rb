Spree::UserSessionsController.class_eval do
  def create
    authenticate_spree_user!

    if spree_user_signed_in?
      respond_to do |format|
        format.html {
          flash[:success] = t(:logged_in_succesfully)
          redirect_back_or_default(after_sign_in_path_for(spree_current_user))
        }
        format.js {
          render json: { email: spree_current_user.login }
        }
      end
    else
      respond_to do |format|
        format.html {
          flash.now[:error] = t('devise.failure.invalid')
          render :new
        }
        format.js {
          render json: { message: t('devise.failure.invalid') }, status: :unprocessable_entity
        }
      end
    end
  end
end