# frozen_string_literal: true

require "system_helper"

describe '
    As a Super Admin
    I want to be able to set a distributor on each payment method
' do
  include WebHelper
  include AuthenticationHelper

  before do
    @distributors = (1..3).map { create(:distributor_enterprise) }
  end

  describe "creating a payment method" do
    it "assigning a distributor to the payment method" do
      login_as_admin_and_visit spree.edit_admin_general_settings_path
      click_link 'Payment Methods'
      click_link 'New Payment Method'

      fill_in 'payment_method_name', with: 'Cheque payment method'

      check "payment_method_distributor_ids_#{@distributors[0].id}"
      click_button 'Create'

      expect(flash_message).to eq('Payment Method has been successfully created!')

      payment_method = Spree::PaymentMethod.find_by(name: 'Cheque payment method')
      expect(payment_method.distributors).to eq([@distributors[0]])
    end

    context "using stripe connect" do
      let(:user) { create(:user, enterprise_limit: 5) }
      let!(:connected_enterprise) {
        create(:distributor_enterprise, name: "Connected", owner: user)
      }
      let!(:revoked_account_enterprise) {
        create(:distributor_enterprise, name: "Revoked", owner: user)
      }
      let!(:missing_account_enterprise) {
        create(:distributor_enterprise, name: "Missing", owner: user)
      }
      let!(:valid_stripe_account) {
        create(:stripe_account, enterprise: connected_enterprise,
                                stripe_user_id: "acc_connected123")
      }
      let!(:disconnected_stripe_account) {
        create(:stripe_account, enterprise: revoked_account_enterprise,
                                stripe_user_id: "acc_revoked123")
      }
      let!(:stripe_account_mock) {
        { id: "acc_connected123", business_name: "My Org", charges_enabled: true }
      }

      before do
        allow(Spree::Config).to receive(:stripe_connect_enabled).and_return(true)
        Stripe.api_key = "sk_test_12345"
        stub_request(:get,
                     "https://api.stripe.com/v1/accounts/acc_connected123").to_return(body: JSON.generate(stripe_account_mock))
        stub_request(:get,
                     "https://api.stripe.com/v1/accounts/acc_revoked123").to_return(status: 404)
      end

      it "communicates the status of the stripe connection to the user" do
        login_as user
        visit spree.new_admin_payment_method_path

        select2_select "Stripe", from: "payment_method_type"

        select2_select "Missing", from: "payment_method_preferred_enterprise_id"
        expect(page).to have_selector "#stripe-account-status .alert-box.error",
                                      text: 'No Stripe account exists for this enterprise.'
        connect_one = 'Connect One'
        expect(page).to have_link connect_one,
                                  href: edit_admin_enterprise_path(missing_account_enterprise,
                                                                   anchor: "/payment_methods")

        select2_select "Revoked", from: "payment_method_preferred_enterprise_id"
        expect(page).to have_selector "#stripe-account-status .alert-box.error",
                                      text: 'Access to this Stripe account has been revoked, please reconnect your account.'

        select2_select "Connected", from: "payment_method_preferred_enterprise_id"
        expect(page).to have_selector "#stripe-account-status .status", text: "Status: Connected"
        expect(page).to have_selector "#stripe-account-status .account_id",
                                      text: "Account ID: acc_connected123"
        expect(page).to have_selector "#stripe-account-status .business_name",
                                      text: "Business Name: My Org"
        expect(page).to have_selector "#stripe-account-status .charges_enabled",
                                      text: "Charges Enabled: Yes"
      end
    end

    it "checking a single distributor is checked by default" do
      2.times.each { Enterprise.last.destroy }
      login_as_admin_and_visit spree.new_admin_payment_method_path
      expect(page).to have_field "payment_method_distributor_ids_#{@distributors[0].id}",
                                 checked: true
    end

    it "checking more than a distributor displays no default choice" do
      login_as_admin_and_visit spree.new_admin_payment_method_path
      expect(page).to have_field "payment_method_distributor_ids_#{@distributors[0].id}",
                                 checked: false
      expect(page).to have_field "payment_method_distributor_ids_#{@distributors[1].id}",
                                 checked: false
      expect(page).to have_field "payment_method_distributor_ids_#{@distributors[2].id}",
                                 checked: false
    end
  end

  it "updating a payment method" do
    payment_method = create(:payment_method, distributors: [@distributors[0]],
                                             calculator: build(:calculator_flat_rate))
    login_as_admin_and_visit spree.edit_admin_payment_method_path payment_method

    fill_in 'payment_method_name', with: 'New PM Name'
    find(:css, "tags-input .tags input").set "member\n"

    uncheck "payment_method_distributor_ids_#{@distributors[0].id}"
    check "payment_method_distributor_ids_#{@distributors[1].id}"
    check "payment_method_distributor_ids_#{@distributors[2].id}"
    select2_select "PayPal Express", from: "payment_method_type"
    expect(page).to have_field 'Login'
    fill_in 'payment_method_preferred_login', with: 'testlogin'
    fill_in 'payment_method_preferred_password', with: 'secret'
    fill_in 'payment_method_preferred_signature', with: 'sig'

    click_button 'Update'

    expect(flash_message).to eq 'Payment Method has been successfully updated!'

    expect(first('tags-input .tag-list ti-tag-item')).to have_content "member"

    payment_method = Spree::PaymentMethod.find_by(name: 'New PM Name')
    expect(payment_method.distributors).to include @distributors[1], @distributors[2]
    expect(payment_method.distributors).not_to include @distributors[0]
    expect(payment_method.type).to eq "Spree::Gateway::PayPalExpress"
    expect(payment_method.preferences[:login]).to eq 'testlogin'
    expect(payment_method.preferences[:password]).to eq 'secret'
    expect(payment_method.preferences[:signature]).to eq 'sig'

    fill_in 'payment_method_preferred_login', with: 'otherlogin'
    click_button 'Update'

    expect(flash_message).to eq 'Payment Method has been successfully updated!'
    expect(page).to have_field 'Password', with: ''
    expect(first('tags-input .tag-list ti-tag-item')).to have_content "member"

    payment_method = Spree::PaymentMethod.find_by(name: 'New PM Name')
    expect(payment_method.tag_list).to eq ["member"]
    expect(payment_method.preferences[:login]).to eq 'otherlogin'
    expect(payment_method.preferences[:password]).to eq 'secret'
    expect(payment_method.preferences[:signature]).to eq 'sig'
  end

  context "as an enterprise user" do
    let(:enterprise_user) { create(:user) }
    let(:distributor1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:distributor2) { create(:distributor_enterprise, name: 'Second Distributor') }
    let(:distributor3) { create(:distributor_enterprise, name: 'Third Distributor') }
    let(:payment_method1) { create(:payment_method, name: 'One', distributors: [distributor1]) }
    let(:payment_method2) {
      create(:payment_method, name: 'Two', distributors: [distributor1, distributor2])
    }
    let(:payment_method3) { create(:payment_method, name: 'Three', distributors: [distributor3]) }

    before(:each) do
      enterprise_user.enterprise_roles.build(enterprise: distributor1).save
      enterprise_user.enterprise_roles.build(enterprise: distributor2).save
      login_as enterprise_user
    end

    it "I can get to the new enterprise page" do
      visit admin_enterprises_path
      within("#e_#{distributor1.id}") { click_link 'Settings' }
      within(".side_menu") do
        click_link "Payment Methods"
      end
      click_link 'Create One Now'
      expect(page).to have_current_path spree.new_admin_payment_method_path
    end

    it "creates payment methods" do
      visit spree.new_admin_payment_method_path
      fill_in 'payment_method_name', with: 'Cheque payment method'
      expect(page).to have_field 'payment_method_description'
      expect(page).to have_select 'payment_method_display_on'

      check "payment_method_distributor_ids_#{distributor1.id}"
      find(:css, "tags-input .tags input").set "local\n"
      click_button 'Create'

      expect(flash_message).to eq('Payment Method has been successfully created!')
      expect(first('tags-input .tag-list ti-tag-item')).to have_content "local"

      payment_method = Spree::PaymentMethod.find_by(name: 'Cheque payment method')
      expect(payment_method.distributors).to eq([distributor1])
      expect(payment_method.tag_list).to eq(["local"])
    end

    it "shows me only payment methods I have access to" do
      payment_method1
      payment_method2
      payment_method3

      visit spree.admin_payment_methods_path

      expect(page).to     have_content payment_method1.name
      expect(page).to     have_content payment_method2.name
      expect(page).not_to have_content payment_method3.name
    end

    it "does not show duplicates of payment methods" do
      payment_method1
      payment_method2

      visit spree.admin_payment_methods_path
      expect(page).to have_selector 'td', text: 'Two', count: 1
    end

    it "shows me only payment methods for the enterprise I select" do
      payment_method1
      payment_method2

      visit admin_enterprises_path
      within("#e_#{distributor1.id}") { click_link 'Settings' }
      within(".side_menu") do
        click_link "Payment Methods"
      end

      expect(page).to     have_content payment_method1.name
      expect(page).to     have_content payment_method2.name

      click_link 'Enterprises'
      within("#e_#{distributor2.id}") { click_link 'Settings' }
      within(".side_menu") do
        click_link "Payment Methods"
      end

      expect(page).to     have_content payment_method1.name
      expect(page).to     have_content payment_method2.name

      expect(page).to have_checked_field "enterprise_payment_method_ids_#{payment_method2.id}"
      expect(page).to have_unchecked_field "enterprise_payment_method_ids_#{payment_method1.id}"
    end
  end

  describe "Setting transaction fees" do
    let!(:payment_method) { create(:payment_method) }
    before { login_as_admin_and_visit spree.edit_admin_payment_method_path payment_method }

    it "set by default 'None' as calculator" do
      expect(page).to have_select "calc_type", selected: "None"
    end

    it "handle the 'None' calculator" do
      select2_select "None", from: 'calc_type'
      click_button 'Update'
      expect(page).to have_content("Payment Method has been successfully updated!")
      expect(payment_method.reload.calculator_type).to eq "Calculator::None"
      expect(page).to have_select "calc_type", selected: "None"
    end

    context "using Flat Percent calculator" do
      before { select2_select "Flat Percent", from: 'calc_type' }

      it "inserts values which persist" do
        expect(page).to have_content("you must save first before")
        click_button 'Update'
        fill_in "Flat Percent", with: '2.5'
        click_button 'Update'
        expect(page).to have_content("Payment Method has been successfully updated!")
        expect(page).to have_field "Flat Percent", with: '2.5'
      end
    end

    context "using Flat Rate (per order) calculator" do
      before { select2_select "Flat Rate (per order)", from: 'calc_type' }

      it "inserts values which persist" do
        expect(page).to have_content("you must save first before")
        click_button 'Update'
        fill_in "Amount", with: 2.2
        click_button 'Update'
        expect(page).to have_content("Payment Method has been successfully updated!")
        expect(page).to have_field "Amount", with: 2.2
      end
    end

    context "using Flexible Rate calculator" do
      before { select2_select "Flexible Rate", from: 'calc_type' }

      it "inserts values which persist" do
        expect(page).to have_content("you must save first before")
        click_button 'Update'
        fill_in "First Item Cost", with: 2
        fill_in "Additional Item Cost", with: 1.1
        fill_in "Max Items", with: 10
        click_button 'Update'
        expect(page).to have_content("Payment Method has been successfully updated!")
        expect(page).to have_field "First Item Cost", with: '2.0'
        expect(page).to have_field "Additional Item Cost", with: '1.1'
        expect(page).to have_field "Max Items", with: '10'
      end
    end

    context "using Flat Rate (per item) calculator" do
      before { select2_select "Flat Rate (per item)", from: 'calc_type' }

      it "inserts values which persist" do
        expect(page).to have_content("you must save first before")
        click_button 'Update'
        fill_in "Amount", with: 2.2
        click_button 'Update'
        expect(page).to have_content("Payment Method has been successfully updated!")
        expect(page).to have_field "Amount", with: 2.2
      end
    end

    context "using Price Sack calculator" do
      before { select2_select "Price Sack", from: 'calc_type' }

      it "inserts values which persist" do
        expect(page).to have_content("you must save first before")
        click_button 'Update'
        fill_in "Minimal Amount", with: 10.2
        fill_in "Normal Amount", with: 2.1
        fill_in "Discount Amount", with: 1.1
        click_button 'Update'
        expect(page).to have_content("Payment Method has been successfully updated!")
        expect(page).to have_field "Minimal Amount", with: '10.2'
        expect(page).to have_field "Normal Amount", with: '2.1'
        expect(page).to have_field "Discount Amount", with: '1.1'
      end
    end
  end
end
