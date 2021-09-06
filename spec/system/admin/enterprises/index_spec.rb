# frozen_string_literal: true

require 'spec_helper'

feature 'Enterprises Index' do
  include WebHelper
  include AuthenticationHelper

  context "as an admin user" do
    scenario "listing enterprises" do
      s = create(:supplier_enterprise)
      d = create(:distributor_enterprise)

      login_as_admin_and_visit admin_enterprises_path

      within("tr.enterprise-#{s.id}") do
        expect(page).to have_content s.name
        expect(page).to have_select "sets_enterprise_set_collection_attributes_1_sells"
        expect(page).to have_content "Settings"
        expect(page).to have_content "Delete"
        expect(page).to have_no_content "Payment Methods"
        expect(page).to have_no_content "Shipping Methods"
        expect(page).to have_content "Enterprise Fees"
      end

      within("tr.enterprise-#{d.id}") do
        expect(page).to have_content d.name
        expect(page).to have_select "sets_enterprise_set_collection_attributes_0_sells"
        expect(page).to have_content "Settings"
        expect(page).to have_content "Delete"
        expect(page).to have_content "Payment Methods"
        expect(page).to have_content "Shipping Methods"
        expect(page).to have_content "Enterprise Fees"
      end
    end

    context "editing enterprises in bulk" do
      let!(:s){ create(:supplier_enterprise) }
      let!(:d){ create(:distributor_enterprise, sells: 'none') }
      let!(:d_manager) { create(:user, enterprise_limit: 1) }

      before do
        d_manager.enterprise_roles.build(enterprise: d).save
        expect(d.owner).to_not eq d_manager
      end

      context "without violating rules" do
        before do
          login_as_admin_and_visit admin_enterprises_path
        end

        it "updates the enterprises" do
          within("tr.enterprise-#{d.id}") do
            expect(page).to have_checked_field "sets_enterprise_set_collection_attributes_0_visible"
            uncheck "sets_enterprise_set_collection_attributes_0_visible"
            select 'any', from: "sets_enterprise_set_collection_attributes_0_sells"
            select d_manager.email, from: 'sets_enterprise_set_collection_attributes_0_owner_id'
          end
          click_button "Update"
          expect(flash_message).to eq('Enterprises updated successfully')
          distributor = Enterprise.find(d.id)
          expect(distributor.visible).to eq false
          expect(distributor.sells).to eq 'any'
          expect(distributor.owner).to eq d_manager
        end
      end

      context "with data that violates rules" do
        let!(:second_distributor) { create(:distributor_enterprise, sells: 'none') }

        before do
          d_manager.enterprise_roles.build(enterprise: second_distributor).save
          expect(d.owner).to_not eq d_manager

          login_as_admin_and_visit admin_enterprises_path
        end

        def enterprise_row_index(enterprise_name)
          enterprise_row_number = all('tr').index { |tr| tr.text.include? enterprise_name }
          enterprise_row_number - 1
        end

        it "does not update the enterprises and displays errors" do
          d_row_index = enterprise_row_index(d.name)
          within("tr.enterprise-#{d.id}") do
            select d_manager.email,
                   from: "sets_enterprise_set_collection_attributes_#{d_row_index}_owner_id"
          end

          second_distributor_row_index = enterprise_row_index(second_distributor.name)
          within("tr.enterprise-#{second_distributor.id}") do
            select d_manager.email,
                   from: "sets_enterprise_set_collection_attributes_#{second_distributor_row_index}_owner_id"
          end
          click_button "Update"
          expect(flash_message).to eq('Update failed')
          expect(page).to have_content "#{d_manager.email} is not permitted to own any more enterprises (limit is 1)."
          second_distributor.reload
          expect(second_distributor.owner).to_not eq d_manager
        end
      end
    end
  end

  describe "as the manager of an enterprise" do
    let(:supplier1) { create(:supplier_enterprise, name: 'First Supplier') }
    let(:supplier2) { create(:supplier_enterprise, name: 'Another Supplier') }
    let(:distributor1) { create(:distributor_enterprise, name: 'First Distributor') }
    let(:distributor2) { create(:distributor_enterprise, name: 'Another Distributor') }
    let(:distributor3) { create(:distributor_enterprise, name: 'Yet Another Distributor') }
    let(:enterprise_manager) { create(:user) }
    let!(:er) {
      create(:enterprise_relationship, parent: distributor3, child: distributor1,
                                       permissions_list: [:edit_profile])
    }

    before(:each) do
      enterprise_manager.enterprise_roles.build(enterprise: supplier1).save
      enterprise_manager.enterprise_roles.build(enterprise: distributor1).save

      login_as enterprise_manager
    end

    context "listing enterprises", js: true do
      it "displays enterprises I have permission to manage" do
        visit admin_enterprises_path

        within("tbody#e_#{distributor1.id}") do
          expect(page).to have_content distributor1.name
          expect(page).to have_selector "td.producer", text: 'Non-Producer'
          expect(page).to have_selector "td.package", text: 'Hub'
        end

        within("tbody#e_#{distributor3.id}") do
          expect(page).to have_content distributor3.name
          expect(page).to have_selector "td.producer", text: 'Non-Producer'
          expect(page).to have_selector "td.package", text: 'Hub'
        end

        within("tbody#e_#{supplier1.id}") do
          expect(page).to have_content supplier1.name
          expect(page).to have_selector "td.producer", text: 'Producer'
          expect(page).to have_selector "td.package", text: 'Profile'
        end

        expect(page).to have_no_content "supplier2.name"
        expect(page).to have_no_content "distributor2.name"

        expect(find('.js-admin-section-header')).to have_link "New Enterprise"
      end

      it "does not give me an option to change or update the package and producer properties of enterprises I manage" do
        visit admin_enterprises_path

        within("tbody#e_#{distributor1.id}") do
          find("td.producer").click
          expect(page).to have_selector "a.selector.producer.disabled"
          find("a.selector.producer.disabled").click
          expect(page).to have_selector "a.selector.non-producer.selected.disabled"
          expect(page).to have_no_selector "a.update"
          find("td.package").click
          expect(page).to have_selector "a.selector.hub-profile.disabled"
          find("a.selector.hub-profile.disabled").click
          expect(page).to have_selector "a.selector.hub.selected.disabled"
          expect(page).to have_no_selector "a.update"
        end
      end
    end
  end

  describe "as the owner of an enterprise" do
    let!(:user) { create(:user) }
    let!(:owned_distributor) {
      create(:distributor_enterprise, name: 'Owned Distributor', owner: user)
    }

    before do
      login_as user
    end

    context "listing enterprises", js: true do
      it "allows me to change or update the package and producer properties of enterprises I manage" do
        visit admin_enterprises_path

        within("tbody#e_#{owned_distributor.id}") do
          # Open the producer panel
          find("td.producer").click

          expect(page).to have_no_selector "a.selector.producer.selected"
          expect(page).to have_selector "a.selector.non-producer.selected"

          # Change to a producer
          find("a.selector.producer").click

          expect(page).to have_no_selector "a.selector.non-producer.selected"
          expect(page).to have_selector "a.selector.producer.selected"
          expect(page).to have_selector "a.update", text: "SAVE"

          # Save selection
          find('a.update').click
          expect(page).to have_selector "a.update", text: "SAVED"
          expect(owned_distributor.reload.is_primary_producer).to eq true

          # Open the package panel
          find("td.package").click

          expect(page).to have_no_selector "a.selector.producer-profile.selected"
          expect(page).to have_no_selector "a.selector.producer-shop.selected"
          expect(page).to have_selector "a.selector.producer-hub.selected"

          # Change to a producer-shop
          find("a.selector.producer-shop").click

          expect(page).to have_no_selector "a.selector.producer-profile.selected"
          expect(page).to have_selector "a.selector.producer-shop.selected"
          expect(page).to have_no_selector "a.selector.producer-hub.selected"
          expect(page).to have_selector "a.update", text: "SAVE"

          # Save selection
          find('a.update').click
          expect(page).to have_selector "a.update", text: "SAVED"
          expect(owned_distributor.reload.sells).to eq "own"
        end
      end
    end
  end
end
