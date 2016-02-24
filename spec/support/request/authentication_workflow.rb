module AuthenticationWorkflow
  include Warden::Test::Helpers

  def quick_login_as(user)
    login_as user
  end

  def quick_login_as_admin
    admin_role = Spree::Role.find_or_create_by_name!('admin')
    admin_user = create(:user,
      :password => 'passw0rd',
      :password_confirmation => 'passw0rd',
      :remember_me => false,
      :persistence_token => 'pass',
      :login => 'admin@ofn.org')

    admin_user.spree_roles << admin_role
    quick_login_as admin_user
    admin_user
  end

  def stub_authorization!
    before(:all) { Spree::Ability.register_ability(AuthorizationHelpers::Request::SuperAbility) }
    after(:all) { Spree::Ability.remove_ability(AuthorizationHelpers::Request::SuperAbility) }
  end

  def login_to_admin_section
    admin_role = Spree::Role.find_or_create_by_name!('admin')
    admin_user = create(:user,
      :password => 'passw0rd',
      :password_confirmation => 'passw0rd',
      :remember_me => false,
      :persistence_token => 'pass',
      :login => 'admin@ofn.org')

    admin_user.spree_roles << admin_role
    quick_login_as admin_user
    visit spree.admin_path
  end

  # TODO: Should probably just rename this to create_user
  def create_enterprise_user( attrs = {} )
    new_user = create(:user, attrs)
    new_user.spree_roles = [] # for some reason unbeknown to me, this new user gets admin permissions by default.
    new_user.save
    new_user
  end

  def login_to_admin_as user
    quick_login_as user
    visit spree.admin_path
    #visit spree.admin_path
    #fill_in 'spree_user_email', :with => user.email
    #fill_in 'spree_user_password', :with => user.password
    #click_button 'Login'
  end

  def login_to_consumer_section
    user_role = Spree::Role.find_or_create_by_name!('user')
    user = create_enterprise_user({
      :email => 'someone@ofn.org',
      :password => 'passw0rd',
      :password_confirmation => 'passw0rd',
      :remember_me => false,
      :persistence_token => 'pass',
      :login => 'someone@ofn.org'})

    user.spree_roles << user_role

    visit spree.login_path
    fill_in 'email', :with => 'someone@ofn.org'
    fill_in 'password', :with => 'passw0rd'
    click_button 'Login'
  end
end

RSpec.configure do |config|
  config.extend AuthenticationWorkflow, :type => :feature
end
