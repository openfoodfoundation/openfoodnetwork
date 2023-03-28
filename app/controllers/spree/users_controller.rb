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
            partial("layouts/alert", locals: { type: "alert", message: t('devise.failure.already_registered') })
          ).
          dispatch_event(name: "login:modal:open")
      else
        head :not_found
      end
    end

    def create
      @user = Spree::User.new(user_params)

      if @user.save
        render cable_ready: cable_car.inner_html(
          "#signup-feedback",
          partial("layouts/alert", locals: { type: "success", message: t('devise.user_registrations.spree_user.signed_up_but_unconfirmed') })
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

    private

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
  end
end
