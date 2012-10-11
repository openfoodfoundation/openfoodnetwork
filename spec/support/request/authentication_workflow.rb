module AuthenticationWorkflow
  def login_to_admin_section
    admin_role = Spree::Role.create(:name => 'admin')
    admin_user = Spree::User.create({
      :email => 'admin@ofw.org',
      :password => 'passw0rd',
      :password_confirmation => 'passw0rd',
      :remember_me => false,
      :persistence_token => 'pass',
      :login => 'admin@ofw.org',
      :role_ids => [admin_role.id]})

    visit spree.admin_path
    fill_in 'user_email', :with => 'admin@ofw.org'
    fill_in 'user_password', :with => 'passw0rd'
    click_button 'Login'
  end

  def login_to_consumer_section
    # The first user is given the admin role by Spree, so create a dummy user if this is the first
    create(:user) if Spree::User.admin.empty?

    user_role = Spree::Role.create(:name => 'user')
    user = Spree::User.create({
      :email => 'someone@ofw.org',
      :password => 'passw0rd',
      :password_confirmation => 'passw0rd',
      :remember_me => false,
      :persistence_token => 'pass',
      :login => 'someone@ofw.org',
      :role_ids => [user_role.id]})

    visit spree.root_path
    click_link 'Login'
    fill_in 'user_email', :with => 'someone@ofw.org'
    fill_in 'user_password', :with => 'passw0rd'
    click_button 'Login'
  end
end
