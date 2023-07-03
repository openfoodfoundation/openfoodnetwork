# frozen_string_literal: true

require 'system_helper'

describe '
    As an entreprise user
    I want to manage vouchers
' do
  include WebHelper
  include AuthenticationHelper

  let(:enterprise) { create(:supplier_enterprise, name: 'Feedme', sells: 'own') }
  let(:voucher_code) { 'awesomevoucher' }
  let(:amount) { 25 }
  let(:enterprise_user) { create(:user, enterprise_limit: 1) }

  before do
    Flipper.enable(:vouchers)

    enterprise_user.enterprise_roles.build(enterprise: enterprise).save
    login_as enterprise_user
  end

  it 'lists enterprise vouchers' do
    # Given an enterprise with vouchers
    create(:voucher_flat_rate, enterprise: enterprise, code: voucher_code, amount: amount)

    # When I go to the enterprise voucher tab
    visit edit_admin_enterprise_path(enterprise)

    click_link 'Vouchers'

    # Then I see a list of vouchers
    expect(page).to have_content voucher_code
    expect(page).to have_content amount
  end

  describe "adding voucher" do
    before do
      # Given an enterprise
      # When I go to the enterprise voucher tab and click new
      visit edit_admin_enterprise_path(enterprise)

      click_link 'Vouchers'
      within "#vouchers_panel" do
        click_link 'Add New'
      end
    end

    context "with a flat rate voucher" do
      it 'creates a voucher' do
        # And I fill in the fields for a new voucher click save
        fill_in 'vouchers_flat_rate_code', with: voucher_code
        select "Flat", from: "vouchers_flat_rate_voucher_type"
        fill_in 'vouchers_flat_rate_amount', with: amount
        click_button 'Save'

        # Then I should get redirect to the entreprise voucher tab and see the created voucher
        expect_to_be_redirected_to_enterprise_voucher_tab(page, voucher_code, amount)
        expect_voucher_to_be_created(enterprise, voucher_code)
      end
    end

    context "with a percentage rate voucher" do
      it 'creates a voucher' do
        # And I fill in the fields for a new voucher click save
        fill_in 'vouchers_flat_rate_code', with: voucher_code
        select "Percentage (%)", from: "vouchers_flat_rate_voucher_type"
        fill_in 'vouchers_flat_rate_amount', with: amount
        click_button 'Save'

        # Then I should get redirect to the entreprise voucher tab and see the created voucher
        expect_to_be_redirected_to_enterprise_voucher_tab(page, voucher_code, amount)
        expect_voucher_to_be_created(enterprise, voucher_code)
      end
    end

    context 'when entering invalid data' do
      it 'shows an error flash message' do
        # Given an enterprise
        # When I go to the new voucher page
        visit new_admin_enterprise_voucher_path(enterprise)

        # And I fill in fields with invalid data and click save
        click_button 'Save'

        # Then I should see an error flash message
        expect(page).to have_selector '.error', text: "Code can't be blank"

        vouchers = Voucher.where(enterprise: enterprise)

        expect(vouchers).to be_empty
      end
    end
  end

  def expect_to_be_redirected_to_enterprise_voucher_tab(page, voucher_code, amount)
    expect(page).to have_selector '.success', text: 'Voucher has been successfully created!'
    expect(page).to have_content voucher_code
    expect(page).to have_content amount
  end

  def expect_voucher_to_be_created(enterprise, voucher_code)
    voucher = Voucher.where(enterprise: enterprise, code: voucher_code).first
    expect(voucher).not_to be(nil)
  end
end
