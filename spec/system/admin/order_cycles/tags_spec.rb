# frozen_string_literal: true

require 'system_helper'

RSpec.describe '
    As an administrator
    I want to manage order cycle tags
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  it "adds and removes a tag under outgoing products" do
    c = create(:distributor_enterprise, is_primary_producer: true)

    # OC with a mono-enterprise outgoing exchange
    oc_outgoing = create(:simple_order_cycle, coordinator: c, distributors: [c])

    login_as_admin
    visit admin_order_cycle_outgoing_path(oc_outgoing)
    expect(page).to have_button "Save", disabled: true
    find("#tags").click
    # add one tag
    find("#tags_with_translation").fill_in with: "Tag 1"

    expect(page).to have_content('You have unsaved changes')
    expect(page).to have_button "Save", disabled: false
    click_on "Save"
    expect(page).to have_content('Your order cycle has been updated')

    page.refresh
    find("#tags").click

    within(".tags .tag-list") do
      expect(page).to have_content 'tag-1'
    end

    # There is only one tag here so first and only tag is correct target
    # Important to test use case with only one tag as there was a bug with
    # this scenario. For future specs, add some other test cases but this
    # one should not be removed/replaced
    find('.remove-button').click
    expect(page).to have_content('You have unsaved changes')
    expect(page).to have_button "Save", disabled: false
  end
end
