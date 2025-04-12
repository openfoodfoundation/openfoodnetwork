# frozen_string_literal: true

module Spree
  class UsersController < ::BaseController
    include I18nHelper

    layout 'darkswarm'

    invisible_captcha only: [:create], on_timestamp_spam: :render_alert_timestamp_error_message
    skip_before_action :set_current_order, only: :show
    prepend_before_action :load_object, only: [:show, :edit, :update]
    prepend_before_action :authorize_actions, only: :new

    before_action :set_locale

    def show
      @payments_requiring_action = PaymentsRequiringActionQuery.new(spree_current_user).call
      @orders = orders_collection.includes(:line_items)

      customers = spree_current_user.customers
      @shops = Enterprise
        .where(id: @orders.pluck(:distributor_id).uniq | customers.pluck(:enterprise_id))

      @unconfirmed_email = spree_current_user.unconfirmed_email
    end

    def create
      @user = Spree::User.new(user_params)

      if @user.save
        flash[:success] = t('devise.user_registrations.spree_user.signed_up_but_unconfirmed')
        redirect_to main_app.root_path
      else
        render turbo_stream: turbo_stream.update(
          'signup-tab',
          partial: 'layouts/signup_tab', locals: { signup_form_user: @user }
        ), status: :unprocessable_entity
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
      CompleteOrdersWithBalanceQuery.new(@user).call
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

    def render_alert_timestamp_error_message
      render turbo_stream: turbo_stream.update(
        'signup-feedback',
        partial: 'layouts/alert',
        locals: { type: "alert", message: InvisibleCaptcha.timestamp_error_message }
      )
    end
  end
end
