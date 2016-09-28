require 'spec_helper'

feature "Connecting a Stripe Account" do
  include AuthenticationWorkflow
  include WebHelper
  before(:each) { login_to_admin_section }
  let!(:enterprise) { create :enterprise }

  scenario "Passing an invalid CSRF token" do
    visit "/stripe/callback?state=%7B%22csrf%22%3D%3E%22ByQF3~~~nonsense~~~4hwwmhAek4u4AEo0%3D%22%2C+%22enterprise_id%22%3D%3E%22#{enterprise.permalink}%22%7D&scope=read_only&code=ac_9HJF2pynjz5vlRWGXtpnGvL3yT9y01DY"
    page.should have_content "Unauthorized" 
  end
end
