# frozen_string_literal: true

require 'system_helper'

describe '
    As an administrator
    I want to manage vouchers
' do
  include WebHelper
  include AuthenticationHelper

  let(:enterprise) { create(:supplier_enterprise, name: 'Feedme') }
  let(:voucher_code) { 'awesomevoucher' }

  it 'lists enterprise vouchers' do
    # Given an enterprise with vouchers
    Voucher.create!(enterprise: enterprise, code: voucher_code)

    # When I go to the enterprise voucher tab
    login_as_admin_and_visit edit_admin_enterprise_path(enterprise)
    click_link 'Vouchers'

    # Then I see a list of vouchers
    expect(page).to have_content voucher_code
    expect(page).to have_content "10"
  end

  it 'creates a voucher' do
    # Given an enterprise
    # When I go to the new voucher page
    login_as_admin_and_visit new_admin_enterprise_voucher_path(enterprise)

    # And I fill in the fields for a new voucher click save
    fill_in 'voucher_code', with: voucher_code
    click_button 'Save'

    # Then I should get redirect to the entreprise voucher tab and see the created voucher
    expect(page).to have_selector '.success', text: 'Voucher has been successfully created!'

    # TODO: doesn't automatically show the voucher tab
    click_link 'Vouchers'

    expect(page).to have_content voucher_code
    expect(page).to have_content "10"

    voucher = Voucher.where(enterprise: enterprise, code: voucher_code).first

    expect(voucher).not_to be(nil)
  end

  context 'when entering invalid data' do
    it 'shows an error flash message' do
      # Given an enterprise
      # When I go to the new voucher page
      login_as_admin_and_visit new_admin_enterprise_voucher_path(enterprise)

      # And I fill in filers with invalid data click save
      click_button 'Save'

      # Then I should see an error flash message
      expect(page).to have_selector '.error', text: "Code can't be blank"

      vouchers = Voucher.where(enterprise: enterprise)

      expect(vouchers).to be_empty
    end
  end
end
