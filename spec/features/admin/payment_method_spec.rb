require "spec_helper"

feature %q{
    As a Super Admin
    I want to be able to set a distributor on each payment method
} do
  include AuthenticationWorkflow
  include WebHelper

  background do
    @distributors = (1..3).map { create(:distributor_enterprise) }
  end

  describe "creating a payment method", js: true do
    scenario "assigning a distributor to the payment method" do
      login_to_admin_section

      click_link 'Configuration'
      click_link 'Payment Methods'
      click_link 'New Payment Method'

      fill_in 'payment_method_name', :with => 'Cheque payment method'
      
      check "payment_method_distributor_ids_#{@distributors[0].id}"
      click_button 'Create'

      flash_message.should == 'Payment Method has been successfully created!'
      
      payment_method = Spree::PaymentMethod.find_by_name('Cheque payment method')
      payment_method.distributors.should == [@distributors[0]]
    end
  end

  context "as an enterprise user" do
    let(:enterprise_user) { create_enterprise_user }
    let(:distributor1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:distributor2) { create(:distributor_enterprise, name: 'Second Distributor') }
    let(:distributor3) { create(:distributor_enterprise, name: 'Third Distributor') }
    let(:pm1) { create(:payment_method, name: 'One', distributors: [distributor1]) }
    let(:pm2) { create(:payment_method, name: 'Two', distributors: [distributor1, distributor2]) }
    let(:pm3) { create(:payment_method, name: 'Three', distributors: [distributor3]) }

    before(:each) do
      enterprise_user.enterprise_roles.build(enterprise: distributor1).save
      enterprise_user.enterprise_roles.build(enterprise: distributor2).save
      login_to_admin_as enterprise_user
    end

    it "I can get to the new enterprise page" do
      click_link 'Enterprises'
      within(".enterprise-#{distributor1.id}") { click_link 'Payment Methods' }
      click_link 'New Payment Method'
      current_path.should == spree.new_admin_payment_method_path
    end

    it "creates payment methods" do
      visit spree.new_admin_payment_method_path
      fill_in 'payment_method_name', :with => 'Cheque payment method'

      check "payment_method_distributor_ids_#{distributor1.id}"
      click_button 'Create'

      flash_message.should == 'Payment Method has been successfully created!'

      payment_method = Spree::PaymentMethod.find_by_name('Cheque payment method')
      payment_method.distributors.should == [distributor1]
    end

    it "shows me only payment methods I have access to" do
      pm1
      pm2
      pm3

      visit spree.admin_payment_methods_path

      page.should     have_content pm1.name
      page.should     have_content pm2.name
      page.should_not have_content pm3.name
    end

    it "does not show duplicates of payment methods" do
      pm1
      pm2

      visit spree.admin_payment_methods_path
      page.all('td', text: 'Two').count.should == 1
    end


    it "shows me only payment methods for the enterprise I select" do
      pm1
      pm2

      click_link 'Enterprises'
      within(".enterprise-#{distributor1.id}") { click_link 'Payment Methods' }
      page.should     have_content pm1.name
      page.should     have_content pm2.name

      click_link 'Enterprises'
      within(".enterprise-#{distributor2.id}") { click_link 'Payment Methods' }
      page.should_not have_content pm1.name
      page.should     have_content pm2.name
    end
  end
end
