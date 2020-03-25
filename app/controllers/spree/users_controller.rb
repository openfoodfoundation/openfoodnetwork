module Spree
  class UsersController < Spree::StoreController
    layout 'darkswarm'
    ssl_required
    skip_before_filter :set_current_order, only: :show
    prepend_before_filter :load_object, only: [:show, :edit, :update]
    prepend_before_filter :authorize_actions, only: :new

    include Spree::Core::ControllerHelpers
    include I18nHelper

    before_filter :set_locale
    before_filter :enable_embedded_shopfront

    # Ignores invoice orders, only order where state: 'complete'
    def show
      @orders = @user.orders.where(state: 'complete').order('completed_at desc')
      @unconfirmed_email = spree_current_user.unconfirmed_email
    end

    # Endpoint for queries to check if a user is already registered
    def registered_email
      user = Spree.user_class.find_by email: params[:email]
      render json: { registered: user.present? }
    end

    def create
      @user = Spree::User.new(user_params)
      if @user.save

        if current_order
          session[:guest_token] = nil
        end

        redirect_back_or_default(main_app.root_url)
      else
        render :new
      end
    end

    def update
      if @user.update_attributes(user_params)
        if params[:user][:password].present?
          # this logic needed b/c devise wants to log us out after password changes
          Spree::User.reset_password_by_token(params[:user])
          sign_in(@user, event: :authentication,
                         bypass: true)
        end
        redirect_to spree.account_url, notice: Spree.t(:account_updated)
      else
        render :edit
      end
    end

    private

    def load_object
      @user ||= spree_current_user
      if @user
        authorize! params[:action].to_sym, @user
      else
        redirect_to spree.login_path
      end
    end

    def authorize_actions
      authorize! params[:action].to_sym, Spree::User.new
    end

    def accurate_title
      Spree.t(:my_account)
    end

    def user_params
      ::PermittedAttributes::User.new(params).call
    end
  end
end
