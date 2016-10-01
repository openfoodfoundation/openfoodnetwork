require 'spec_helper'

feature "Connecting a Stripe Account" do
  include AuthenticationWorkflow
  include WebHelper
  before(:each) { login_to_admin_section }
  let!(:enterprise) { create :enterprise }

end
