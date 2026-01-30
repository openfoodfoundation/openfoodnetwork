# frozen_string_literal: true

RSpec.describe "/admin/user_invitations" do
  let(:enterprise) { create(:distributor_enterprise) }
  let(:params) { { enterprise_id: enterprise.permalink } }
  let(:user) { create(:user) }

  describe "#new" do
    it "renders the user invitation modal via turbo" do
      login_as enterprise.owner

      get new_admin_enterprise_user_invitation_path(enterprise, format: :turbo_stream)

      expect(response.body).to include '<turbo-stream action="update" target="remote_modal">'
    end

    it "redirects the user to the unauthorized path if they are not authorised" do
      login_as user

      get new_admin_enterprise_user_invitation_path(enterprise, format: :turbo_stream)

      expect(response).to redirect_to unauthorized_path
    end
  end

  describe "#create" do
    it "creates the invitation, displays a success flash, closes the modal and updates the users " \
       "panel via turbo if the user is authorised" do
      login_as enterprise.owner

      post admin_enterprise_user_invitations_path(
        enterprise,
        user_invitation: { email: "invitee@example.com" },
        format: :turbo_stream
      )

      expect(flash[:success]).to be_present
      expect(response.body).to include '<turbo-stream action="update" target="remote_modal">'
      expect(response.body).to include '<turbo-stream action="update" target="users_panel">'
    end

    it "redirects the user to the unauthorized path if they are not authorised" do
      login_as user

      post admin_enterprise_user_invitations_path(
        enterprise,
        user_invitation: { email: "invitee@example.com" },
        format: :turbo_stream
      )

      expect(response).to redirect_to unauthorized_path
    end
  end
end
