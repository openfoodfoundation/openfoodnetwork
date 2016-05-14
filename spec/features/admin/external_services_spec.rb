require 'spec_helper'

feature 'External services' do
  include AuthenticationWorkflow

  describe "bugherd" do
    before do
      Spree::Config.bugherd_api_key = nil
      login_to_admin_section
    end

    it "lets me set an API key" do
      visit spree.edit_admin_general_settings_path

      fill_in 'bugherd_api_key', with: 'abc123'
      click_button 'Update'

      page.should have_content 'General Settings has been successfully updated!'
      expect(Spree::Config.bugherd_api_key).to eq 'abc123'
    end
  end
end
