# frozen_string_literal: true

class UserConfirmationsController < DeviseController
  # Needed for access to current_ability, so we can authorize! actions
  include Spree::Core::ControllerHelpers::Auth
  include CablecarResponses

  # GET /resource/confirmation/new
  def new
    build_resource({})
  end

  # POST /resource/confirmation
  def create
    set_return_url if params.key? :return_url
    self.resource = resource_class.send_confirmation_instructions(resource_params)

    if is_navigational_format?
      if successfully_sent?(resource)
        set_flash_message(:success, :confirmation_sent)
      else
        set_flash_message(:error, :confirmation_not_sent)
      end
    else
      render cable_ready: cable_car.inner_html(
        "##{params[:tab] || 'forgot'}-feedback",
        partial("layouts/alert", locals: { type: "success", message: t("devise.confirmations.send_instructions") })
      )
      return
    end

    respond_with_navigational(resource){ redirect_to login_path }
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource) }
  end

  protected

  def set_return_url
    session[:confirmation_return_url] = params[:return_url]
  end

  def after_confirmation_path_for(resource)
    result = resource.errors.empty? ? "confirmed" : "not_confirmed"

    if result == 'confirmed' && resource.reset_password_token.present?
      return spree.edit_spree_user_password_path(
        reset_password_token: resource.regenerate_reset_password_token
      )
    end

    path = session[:confirmation_return_url] || root_path(anchor: "/login")
    append_query_to_url(path, "validation", result)
  end

  private

  def append_query_to_url(url, key, value)
    uri = URI.parse(url.to_s)
    query = URI.decode_www_form(uri.query || "") << [key, value]
    uri.query = URI.encode_www_form(query)

    uri.to_s
  end
end
