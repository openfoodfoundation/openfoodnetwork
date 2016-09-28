require 'spec_helper'

feature %q{
    As a consumer
    I want to view my order history with each hub
    and view any outstanding balance.
}, js: true do
  include UIComponentHelper
  include AuthenticationWorkflow
  let!(:user) { create(:user, bill_address: create(:address))}
  let!(:user2) {create(:user)}
  let!(:distributor1) { create(:distributor_enterprise) }
  let!(:distributor2) { create(:distributor_enterprise) }
  let!(:distributor_credit) { create(:distributor_enterprise) }
  let!(:distributor_without_orders) { create(:distributor_enterprise) }
  let!(:accounts_distributor) {create :distributor_enterprise}
  let!(:order_account_invoice) { create(:order, distributor: accounts_distributor, state: 'complete', user: user) }
  let!(:d1o1) { create(:completed_order_with_totals, distributor_id: distributor1.id, user_id: user.id, total: 10000)}
  let!(:d1o2) { create(:order_without_full_payment, distributor_id: distributor1.id, user_id: user.id, total: 5000)}
  let!(:d2o1) { create(:completed_order_with_totals, distributor_id: distributor2.id, user_id: user.id)}
  let!(:credit_order) { create(:order_with_credit_payment, distributor_id: distributor_credit.id, user_id: user.id)}
#  let!(:credit_payment) { create(:payment, amount: 12000.00, order_id: credit_order.id)}


  before do
    Spree::Config.accounts_distributor_id = accounts_distributor.id
    credit_order.update!
    login_as user
    visit "/account"
  end

  it "shows all hubs that have been ordered from with balance or credit" do
    # Single test to avoid re-rendering page
    expect(page).to have_content distributor1.name
    expect(page).to have_content distributor2.name
    expect(page).not_to have_content distributor_without_orders.name
    # Exclude the special Accounts & Billing distributor
    expect(page).not_to have_content accounts_distributor.name
    expect(page).to have_content distributor1.name + " " + "Balance due"
    expect(page).to have_content distributor_credit.name + " Credit"
  end


  it "reveals table of orders for distributors when clicked" do
    expand_active_table_node distributor1.name
    expect(page).to have_link "Order " + d1o1.number, href:"/orders/#{d1o1.number}"

    expand_active_table_node distributor2.name
    expect(page).not_to have_content "Order " + d1o1.number.to_s
  end

  context "for a user without orders" do
    before do
      login_as user2
      visit "/account"
    end

    it "displays an appropriate message" do
      expect(page).to have_content {t :you_have_no_orders_yet}
    end
  end

  context 'editing user addresses' do
    before do
      visit '/account/edit_address'
    end
    it 'shows billing address in the form' do
      expect(page).to have_field('user[bill_address_attributes][firstname]', with: user.bill_address.firstname)
      expect(page).to have_field('user[bill_address_attributes][address1]', with: user.bill_address.address1)
      expect(page).to have_field('user[bill_address_attributes][phone]', with: user.bill_address.phone)

      expect(page).to have_field('user[bill_address_attributes][state_id]', with: user.bill_address.state_id)
      expect(page).to have_field('user[bill_address_attributes][country_id]', with: user.bill_address.country_id)
    end

    it 'updates shipping address' do
      fill_in('user[ship_address_attributes][firstname]', with: 'John')
      fill_in('user[ship_address_attributes][lastname]', with: 'Doe')
      fill_in('user[ship_address_attributes][address1]', with: '11 Lovely Street')
      fill_in('user[ship_address_attributes][phone]', with: '123-456-7890')
      fill_in('user[ship_address_attributes][city]', with: 'Merbourne')
      fill_in('user[ship_address_attributes][zipcode]', with: '3127')

      click_button('Update')

      expect(page).to have_content '11 Lovely Street'
      expect(page).to have_content 'Merbourne'
      expect(page).to have_content '3127'
    end
  end

end
