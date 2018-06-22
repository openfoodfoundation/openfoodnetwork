module Admin
  class ManagerInvitationsController < Spree::Admin::BaseController
    authorize_resource class: false

    def create
      @email = params[:email]
      @enterprise = Enterprise.find(params[:enterprise_id])

      authorize! :edit, @enterprise

      existing_user = Spree::User.find_by_email(@email)

      if existing_user
        render json: { errors: t('admin.enterprises.invite_manager.user_already_exists') }, status: :unprocessable_entity
        return
      end

      new_user = create_new_manager

      if new_user
        render json: { user: new_user.id }, status: :ok
      else
        render json: { errors: t('admin.enterprises.invite_manager.error') }, status: 500
      end
    end

    private

    def create_new_manager
      password = Devise.friendly_token
      new_user = Spree::User.create(email: @email, unconfirmed_email: @email, password: password)
      new_user.reset_password_token = Devise.friendly_token
      # Same time as used in Devise's lib/devise/models/recoverable.rb.
      new_user.reset_password_sent_at = Time.now.utc
      new_user.save!

      @enterprise.users << new_user
      Delayed::Job.enqueue ManagerInvitationJob.new(@enterprise.id, new_user.id)

      new_user
    end
  end
end
