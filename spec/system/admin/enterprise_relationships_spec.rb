# frozen_string_literal: true

require 'system_helper'

describe '
  As an Administrator
  I want to manage relationships between enterprises
' do
  include WebHelper
  include AuthenticationHelper

  context "as a site administrator" do
    before { login_as_admin }

    it "listing relationships" do
      # Given some enterprises with relationships
      e1, e2, e3, e4 = create(:enterprise), create(:enterprise), create(:enterprise),
create(:enterprise)
      create(:enterprise_relationship, parent: e1, child: e2,
                                       permissions_list: [:add_to_order_cycle])
      create(:enterprise_relationship, parent: e2, child: e3, permissions_list: [:manage_products])
      create(:enterprise_relationship, parent: e3, child: e4,
                                       permissions_list: [:add_to_order_cycle, :manage_products])

      # When I go to the relationships page
      visit spree.admin_dashboard_path
      click_link 'Enterprises'
      click_link 'Permissions'

      # Then I should see the relationships
      within('table#enterprise-relationships') do
        expect(page).to have_relationship e1, e2, 'to add to order cycle'
        expect(page).to have_relationship e2, e3, 'to manage products'
        expect_relationship_with_permissions e3, e4, ['to add to order cycle', 'to manage products']
      end
    end

    it "creating a relationship" do
      e1 = create(:enterprise, name: 'One')
      e2 = create(:enterprise, name: 'Two')

      visit admin_enterprise_relationships_path
      select2_select 'One', from: 'enterprise_relationship_parent_id'

      check 'to add to order cycle'
      check 'to manage products'
      uncheck 'to manage products'
      check 'to edit profile'
      check 'to add products to inventory'
      select2_select 'Two', from: 'enterprise_relationship_child_id'
      click_button 'Create'

      # Wait for row to appear since have_relationship doesn't wait
      expect(page).to have_selector 'tr', count: 2
      expect_relationship_with_permissions e1, e2,
                                           ['to add to order cycle', 'to add products to inventory', 'to edit profile']
      er = EnterpriseRelationship.where(parent_id: e1, child_id: e2).first
      expect(er).to be_present
      expect(er.permissions.map(&:name)).to match_array ['add_to_order_cycle', 'edit_profile',
                                                         'create_variant_overrides']
    end

    it "attempting to create a relationship with invalid data" do
      e1 = create(:enterprise, name: 'One')
      e2 = create(:enterprise, name: 'Two')
      create(:enterprise_relationship, parent: e1, child: e2)

      expect do
        # When I attempt to create a duplicate relationship
        visit admin_enterprise_relationships_path
        select2_select 'One', from: 'enterprise_relationship_parent_id'
        select2_select 'Two', from: 'enterprise_relationship_child_id'
        click_button 'Create'

        # Then I should see an error message
        expect(page).to have_content "That relationship is already established."
      end.to change(EnterpriseRelationship, :count).by(0)
    end

    it "deleting a relationship" do
      e1 = create(:enterprise, name: 'One')
      e2 = create(:enterprise, name: 'Two')
      er = create(:enterprise_relationship, parent: e1, child: e2,
                                            permissions_list: [:add_to_order_cycle])

      visit admin_enterprise_relationships_path
      expect(page).to have_relationship e1, e2, 'to add to order cycle'

      accept_alert do
        first("a.delete-enterprise-relationship").click
      end

      expect(page).not_to have_relationship e1, e2
      expect(EnterpriseRelationship.where(id: er.id)).to be_empty
    end
  end

  context "as an enterprise user" do
    let!(:d1) { create(:distributor_enterprise) }
    let!(:d2) { create(:distributor_enterprise) }
    let!(:d3) { create(:distributor_enterprise) }
    let(:enterprise_user) { create(:user, enterprises: [d1] ) }

    let!(:er1) { create(:enterprise_relationship, parent: d1, child: d2) }
    let!(:er2) { create(:enterprise_relationship, parent: d2, child: d1) }
    let!(:er3) { create(:enterprise_relationship, parent: d2, child: d3) }

    before { login_as enterprise_user }

    it "enterprise user can only see relationships involving their enterprises" do
      visit admin_enterprise_relationships_path

      expect(page).to     have_relationship d1, d2
      expect(page).to     have_relationship d2, d1
      expect(page).not_to have_relationship d2, d3
    end

    it "enterprise user can only add their own enterprises as parent" do
      visit admin_enterprise_relationships_path
      expect(page).to have_select2 'enterprise_relationship_parent_id', options: ['', d1.name]
      expect(page).to have_select2 'enterprise_relationship_child_id',
                                   with_options: ['', d1.name, d2.name, d3.name]
    end
  end

  private

  def have_relationship(parent, child, permission = "")
    have_table_row [parent.name, 'permits', child.name, permission, '']
  end

  def expect_relationship_with_permissions(parent, child, permissions = [])
    tr = find_relationship(parent, child)
    td = tr.find('td:nth-child(4)')
    permissions.each_with_index do |permission, index|
      expect(td.find("li:nth-child(#{index + 1})").text).to eq permission
    end
  end

  def find_relationship(parent, child)
    page.all('tr').each do |tr|
      return tr if tr.find('td:first-child').text == parent.name &&
                   tr.find('td:nth-child(2)').text == "permits" &&
                   tr.find('td:nth-child(3)').text == child.name
    end
    raise "relationship not found"
  end
end
