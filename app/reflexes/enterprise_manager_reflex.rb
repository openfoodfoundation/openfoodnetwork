# frozen_string_literal: true

class EnterpriseManagerReflex < ApplicationReflex
  def update(owner_id, contact_id, manager_ids)
    owner = Spree::User.find(owner_id)
    contact = Spree::User.find(contact_id)
    managers = Spree::User.find(manager_ids)
    morph '#managers',
          render(partial: 'admin/enterprises/form/manager', collection: managers,
                 locals: { owner: owner, contact_person: contact })
  end

  def create_registered_manager
    manager = Spree::User.find(element.value)
    cable_ready.append(selector: "#managers",
                       html: render(partial: 'admin/enterprises/form/manager',
                                    locals: { manager: manager, owner: nil,
                                              contact_person: nil })).broadcast
    morph :nothing
  end

  def create_unregistered_manager(user_id)
    manager = Spree::User.find(user_id)
    cable_ready.inner_html(selector: "#invite-manager-modal .alert-box",
                           html: I18n.t('.user_invited',
                                        email: manager.email)).broadcast
    cable_ready.append(selector: "#managers",
                       html: render(partial: 'admin/enterprises/form/manager',
                                    locals: { manager: manager, owner: nil,
                                              contact_person: nil })).broadcast
    morph :nothing
  end

  def delete
    id = element.dataset["manager-id"]
    manager = Spree::User.find(id)
    cable_ready.remove selector: dom_id(manager, :manager)
    morph :nothing
  end
end
