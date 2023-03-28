# frozen_string_literal: true

class UserPasswordsController < Spree::UserPasswordsController
  include CablecarResponses

  layout 'darkswarm'

  def create
    return render_unconfirmed_response if user_unconfirmed?

    self.resource = resource_class.send_reset_password_instructions(raw_params[resource_name])

    if resource.errors.empty?
      render cable_ready: cable_car.inner_html(
        "#forgot-feedback",
        partial("layouts/alert", locals: { type: "success", message: t(:password_reset_sent) })
      )
    else
      render status: :not_found, cable_ready: cable_car.inner_html(
        "#forgot-feedback",
        partial("layouts/alert", locals: { type: "alert", message: t(:email_not_found) })
      )
    end
  end

  private

  def render_unconfirmed_response
    render status: :unprocessable_entity, cable_ready: cable_car.inner_html(
      "#forgot-feedback",
      partial("layouts/alert",
              locals: { type: "alert", message: t(:email_unconfirmed),
                        unconfirmed: true, tab: "forgot" })
    )
  end

  def user_unconfirmed?
    user = Spree::User.find_by(email: params.dig(:spree_user, :email))
    user && !user.confirmed?
  end
end
