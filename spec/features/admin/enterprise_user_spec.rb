require "spec_helper"

feature %q{
    As a Super User
    I want to setup users to manage an enterprise
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    @new_user = create(:user, :email => 'enterprise@hub.com')
    @enterprise1 = create(:enterprise, name: 'Enterprise 1')
    @enterprise2 = create(:enterprise, name: 'Enterprise 2')
    @enterprise3 = create(:enterprise, name: 'Enterprise 3')
    @enterprise4 = create(:enterprise, name: 'Enterprise 4')
  end

  context "creating an Enterprise User" do
    context 'with no enterprises' do
      scenario "assigning a user to an Enterprise" do
        login_to_admin_section

        click_link 'Users'
        click_link @new_user.email
        click_link 'Edit'

        check @enterprise2.name

        click_button 'Update'

        @new_user.enterprises.count.should == 1
        @new_user.enterprises.first.name.should == @enterprise2.name
      end

    end

    context 'with existing enterprises' do

      before(:each) do
        @new_user.enterprise_roles.build(enterprise: @enterprise1).save
        @new_user.enterprise_roles.build(enterprise: @enterprise3).save
      end

      scenario "removing and add enterprises for a user" do
        login_to_admin_section

        click_link 'Users'
        click_link @new_user.email
        click_link 'Edit'

        uncheck @enterprise3.name # remove
        check @enterprise4.name # add

        click_button 'Update'

        @new_user.enterprises.count.should == 2
        @new_user.enterprises.should include(@enterprise1)
        @new_user.enterprises.should include(@enterprise4)
      end

    end


  end
end
