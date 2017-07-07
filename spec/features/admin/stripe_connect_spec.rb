require 'spec_helper'

feature "Connecting a Stripe Account" do
  include AuthenticationWorkflow
  include WebHelper

  let!(:enterprise_user) { create :enterprise_user }
  before(:each) do
    login_to_admin_as enterprise_user
  end
end
