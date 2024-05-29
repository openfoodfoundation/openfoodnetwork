# frozen_string_literal: true

module Spree
  class UsersController < ::BaseController
    include Spree::Core::ControllerHelpers
    include I18nHelper
    include CablecarResponses

    layout 'darkswarm'

    skip_before_action :set_current_order, only: :show
    prepend_before_action :load_object, only: [:show, :edit, :update]
    prepend_before_action :authorize_actions, only: :new

    before_action :set_locale
    before_action :load_enterprises, only: [:edit, :update, :show]

    def show
      @payments_requiring_action = PaymentsRequiringAction.new(spree_current_user).query
      @orders = orders_collection.includes(:line_items)

      customers = spree_current_user.customers
      @shops = Enterprise
        .where(id: @orders.pluck(:distributor_id).uniq | customers.pluck(:enterprise_id))

      @unconfirmed_email = spree_current_user.unconfirmed_email
    end

    # Endpoint for queries to check if a user is already registered
    def registered_email
      registered = Spree::User.find_by(email: params[:email]).present?

      if registered
        render status: :ok, cable_ready: cable_car.
          inner_html(
            "#login-feedback",
            partial("layouts/alert",
                    locals: { type: "alert", message: t('devise.failure.already_registered') })
          ).
          dispatch_event(name: "login:modal:open")
      else
        head :not_found
      end
    end

    def create
      @user = Spree::User.new(user_params)

      if @user.save
        create_enterprise_role
        render cable_ready: cable_car.inner_html(
          "#signup-feedback",
          partial("layouts/alert",
                  locals: {
                    type: "success",
                    message: t('devise.user_registrations.spree_user.signed_up_but_unconfirmed')
                  })
        )
      else
        render status: :unprocessable_entity, cable_ready: cable_car.morph(
          "#signup-tab",
          partial("layouts/signup_tab", locals: { signup_form_user: @user })
        )
      end
    end

    def update
      if @user.update(user_params)
        if params[:user][:password].present?
          # this logic needed b/c devise wants to log us out after password changes
          Spree::User.reset_password_by_token(params[:user])
          bypass_sign_in(@user)
        end
        redirect_to spree.account_url, notice: Spree.t(:account_updated)
      else
        render :edit
      end
    end

    def approve_enterprise_request
      user = User.find_by(request_token: params[:token])
      if user          
        enterprise = Enterprise.find(params[:enterprise_id])
        user.enterprises << enterprise unless user.enterprises.include?(enterprise)
        user.update(request_token: nil)
        @message = t('enterprise_assigned')           
        RequestMailer.approval_notification(user.email, "Enterprise #{enterprise.name} successfully assigned.")
      else
        @message = t('token_expired')
      end
    end

    def request_enterprise
      if params[:enterprises].present?
        user = User.find(params[:user_id])
        enterprise = Enterprise.find(params[:enterprises])
        request_token(user)
        RequestMailer.request_email(user, enterprise, user.request_token).deliver_now
        flash.now[:success] = "Request email sent."
        redirect_to spree.account_url, notice: "Request email has been sent successfully."
      else
        redirect_to spree.account_url, notice: "Please select an enterprise to request."
      end
    end

    private

    def load_enterprises       
      @enterprises = Enterprise.where.not(id: @user.enterprise_ids).where(visible: "private")
    end

    def orders_collection
      CompleteOrdersWithBalance.new(@user).query
    end

    def load_object
      @user ||= spree_current_user
      if @user && !@user.disabled
        authorize! params[:action].to_sym, @user
      else
        redirect_to main_app.login_path
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

    def private_shop_access(user, enterprise)
      request_token(user)
      RequestMailer.request_email(user, enterprise, user.request_token).deliver_now
    end

    def request_token(user)
      if user.request_token.blank?
        user.request_token = SecureRandom.urlsafe_base64
        user.save!
      end
    end

    def create_enterprise_role      
      enterprise = Enterprise.find(params[:user][:shop_id])

      if enterprise.private?
        private_shop_access(@user, enterprise)
      else
        # create_enterprise_role_query(enterprise.id)        
        enterprise = Enterprise.find(enterprise.id)
        @user.enterprises << enterprise unless @user.enterprises.include?(enterprise)
      end
    end

    # def create_enterprise_role_query(enterprise_id)
    #   # @user.enterprise_roles.create(enterprise_id: enterprise_id, receives_notifications: true)
    #   enterprise = Enterprise.find(enterprise_id)
    #   user.enterprises << enterprise unless user.enterprises.include?(enterprise)
    # end
  end
end
