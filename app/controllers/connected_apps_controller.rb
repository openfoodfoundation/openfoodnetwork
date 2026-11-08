# frozen_string_literal: true

# Users revoke an external application from the Connected Apps tab of their
# account. Doorkeeper's controller authenticates the user and does the
# revoking; we only send them back to the tab.
class ConnectedAppsController < Doorkeeper::AuthorizedApplicationsController
  def destroy
    application = Doorkeeper::Application.find(params[:id])
    Doorkeeper::Application.revoke_tokens_and_grants_for(application.id, current_resource_owner)

    flash[:success] = t(".success", name: application.name)
    redirect_to "#{spree.account_path}#/connected_apps"
  end
end
