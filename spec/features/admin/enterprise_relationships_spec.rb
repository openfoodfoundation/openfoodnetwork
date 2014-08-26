require 'spec_helper'

feature %q{
  As an Administrator
  I want to manage relationships between enterprises
}, js: true do
  include AuthenticationWorkflow
  include WebHelper


  context "as a site administrator" do
    before { login_to_admin_section }

    scenario "listing relationships" do
      # Given some enterprises with relationships
      e1, e2, e3, e4 = create(:enterprise), create(:enterprise), create(:enterprise), create(:enterprise)
      create(:enterprise_relationship, parent: e1, child: e2, permissions_list: [:add_to_order_cycle])
      create(:enterprise_relationship, parent: e2, child: e3, permissions_list: [:manage_products])
      create(:enterprise_relationship, parent: e3, child: e4, permissions_list: [:add_to_order_cycle, :manage_products])

      # When I go to the relationships page
      click_link 'Enterprises'
      click_link 'Relationships'

      # Then I should see the relationships
      within('table#enterprise-relationships') do
        page.should have_relationship e1, e2, ['can add to order cycle']
        page.should have_relationship e2, e3, ['can manage the products of']
        page.should have_relationship e3, e4,
          ['can add to order cycle', 'can manage the products of']
      end
    end


    scenario "creating a relationship" do
      e1 = create(:enterprise, name: 'One')
      e2 = create(:enterprise, name: 'Two')

      visit admin_enterprise_relationships_path
      select 'One', from: 'enterprise_relationship_parent_id'
      check 'can add to order cycle'
      check 'can manage the products of'
      uncheck 'can manage the products of'
      select 'Two', from: 'enterprise_relationship_child_id'
      click_button 'Create'

      page.should have_relationship e1, e2, ['can add to order cycle']
      er = EnterpriseRelationship.where(parent_id: e1, child_id: e2).first
      er.should be_present
      er.permissions.map(&:name).should == ['add_to_order_cycle']
    end


    scenario "attempting to create a relationship with invalid data" do
      e1 = create(:enterprise, name: 'One')
      e2 = create(:enterprise, name: 'Two')
      create(:enterprise_relationship, parent: e1, child: e2)

      expect do
        # When I attempt to create a duplicate relationship
        visit admin_enterprise_relationships_path
        select 'One', from: 'enterprise_relationship_parent_id'
        select 'Two', from: 'enterprise_relationship_child_id'
        click_button 'Create'

        # Then I should see an error message
        page.should have_content "That relationship is already established."
      end.to change(EnterpriseRelationship, :count).by(0)
    end


    scenario "deleting a relationship" do
      e1 = create(:enterprise, name: 'One')
      e2 = create(:enterprise, name: 'Two')
      er = create(:enterprise_relationship, parent: e1, child: e2)

      visit admin_enterprise_relationships_path
      page.should have_relationship e1, e2

      first("a.delete-enterprise-relationship").click

      page.should_not have_relationship e1, e2
      EnterpriseRelationship.where(id: er.id).should be_empty
    end
  end


  context "as an enterprise user" do
    let!(:d1) { create(:distributor_enterprise) }
    let!(:d2) { create(:distributor_enterprise) }
    let!(:d3) { create(:distributor_enterprise) }
    let(:enterprise_user) { create_enterprise_user([d1]) }

    let!(:er1) { create(:enterprise_relationship, parent: d1, child: d2) }
    let!(:er2) { create(:enterprise_relationship, parent: d2, child: d1) }
    let!(:er3) { create(:enterprise_relationship, parent: d2, child: d3) }

    before { login_to_admin_as enterprise_user }

    scenario "enterprise user can only see relationships involving their enterprises" do
      visit admin_enterprise_relationships_path

      page.should     have_relationship d1, d2
      page.should     have_relationship d2, d1
      page.should_not have_relationship d2, d3
    end


    scenario "enterprise user can only add their own enterprises as parent" do
      visit admin_enterprise_relationships_path
      page.should have_select 'enterprise_relationship_parent_id', options: ['', d1.name]
      page.should have_select 'enterprise_relationship_child_id', options: ['', d1.name, d2.name, d3.name]
    end
  end


  private

  def have_relationship(parent, child, perms=[])
    perms = perms.join(' ') || 'permits'

    have_table_row [parent.name, perms, child.name, '']
  end
end
