module AuthenticationWorkflow
  include Warden::Test::Helpers

  def quick_login_as(user)
    login_as user
  end

  def quick_login_as_admin
    admin_role = Spree::Role.find_or_create_by!(name: 'admin')
    admin_user = create(:user,
                        password: 'passw0rd',
                        password_confirmation: 'passw0rd',
                        remember_me: false,
                        persistence_token: 'pass',
                        login: 'admin@ofn.org')

    admin_user.spree_roles << admin_role
    quick_login_as admin_user
    admin_user
  end

  def login_to_admin_section
    quick_login_as_admin
    visit spree.admin_dashboard_path
  end

  # TODO: Should probably just rename this to create_user
  def create_enterprise_user( attrs = {} )
    new_user = build(:user, attrs)
    new_user.spree_roles = [Spree::Role.find_or_create_by!(name: 'user')]
    new_user.save
    if attrs.key? :enterprises
      attrs[:enterprises].each do |enterprise|
        enterprise.users << new_user
      end
    end
    new_user
  end

  def login_to_admin_as(user)
    quick_login_as user
    visit spree.admin_dashboard_path
    # visit spree.admin_dashboard_path
    # fill_in 'spree_user_email', :with => user.email
    # fill_in 'spree_user_password', :with => user.password
    # click_button 'Login'
  end

  def login_to_consumer_section
    user_role = Spree::Role.find_or_create_by!(name: 'user')
    user = create_enterprise_user(
      email: 'someone@ofn.org',
      password: 'passw0rd',
      password_confirmation: 'passw0rd',
      remember_me: false,
      persistence_token: 'pass',
      login: 'someone@ofn.org'
    )

    user.spree_roles << user_role

    visit spree.login_path
    fill_in_and_submit_login_form user
  end

  def fill_in_and_submit_login_form(user)
    fill_in "email", with: user.email
    fill_in "password", with: user.password
    click_button "Login"
  end
end

RSpec.configure do |config|
  config.extend AuthenticationWorkflow, type: :feature

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!
end
