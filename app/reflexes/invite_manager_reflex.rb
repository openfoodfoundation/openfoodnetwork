# frozen_string_literal: true

class InviteManagerReflex < ApplicationReflex
  include ManagerInvitations

  def invite
    email = params[:email]
    enterprise = Enterprise.find(params[:enterprise_id])

    authorize! :edit, enterprise

    existing_user = Spree::User.find_by(email: email)

    locals = { error: nil, success: nil, email: email, enterprise: enterprise }

    if existing_user
      locals[:error] = I18n.t('admin.enterprises.invite_manager.user_already_exists')

      return_morph(locals)
      return
    end

    begin
      new_user = create_new_manager(email, enterprise)
      locals[:success] = true
      locals[:email] = new_user.email
    rescue StandardError => e
      @error = e.message
      locals[:error] = @error || I18n.t('admin.enterprises.invite_manager.error')
    end

    return_morph(locals)
  end

  private

  def return_morph(locals)
    morph "#add_manager_modal",
          with_locale {
            render(partial: "admin/enterprises/form/add_new_unregistered_manager", locals: locals)
          }
  end
end
