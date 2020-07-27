module AuthenticationHelper
  include Warden::Test::Helpers

  def login_as_admin
    admin_role = Spree::Role.find_or_create_by!(name: 'admin')
    admin_user = create(:user,
                        password: 'passw0rd',
                        password_confirmation: 'passw0rd',
                        remember_me: false,
                        persistence_token: 'pass',
                        login: 'admin@ofn.org')

    admin_user.spree_roles << admin_role
    login_as admin_user
    admin_user
  end

  def login_as_admin_and_visit(path_visit)
    login_as_admin
    visit path_visit
  end

  def login_to_admin_section
    login_as_admin_and_visit(spree.admin_dashboard_path)
  end

  def login_to_admin_as(user)
    login_as user
    visit spree.admin_dashboard_path
  end

  def fill_in_and_submit_login_form(user)
    fill_in "email", with: user.email
    fill_in "password", with: user.password
    click_button "Login"
  end

  def expect_logged_in
    # Ensure page has been reloaded after submitting login form
    expect(page).to_not have_selector ".menu #login-link"
  end
end

RSpec.configure do |config|
  config.extend AuthenticationHelper, type: :feature

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
