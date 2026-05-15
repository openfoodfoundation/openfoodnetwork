# frozen_string_literal: true

# Controller used to provide the Persons API for the DFC application
module DfcProvider
  class PersonsController < DfcProvider::ApplicationController
    before_action :check_user_accessibility, only: :show

    def show
      person = PersonBuilder.person(user)
      render json: DfcIo.export(person)
    end

    def prefs
      # You can only see your own preferences for now.
      return not_found if current_user.id != params[:person_id].to_i

      id = person_prefs_url(params[:person_id])
      webid = person_webid_url(params[:person_id])
      type_index = person_private_type_index_url(params[:person_id])
      prefs = {
        '@graph': [
          {
            '@id': id,
            '@type': "pim:ConfigurationFile",
          },
          {
            '@id': "#{webid}#me",
            'solid:privateTypeIndex': type_index
          }
        ]
      }

      render(json: prefs, content_type: "application/ld+json")
    end

    def private_type_index
      # You can only see your own for now.
      return not_found if current_user.id != params[:person_id].to_i

      id = person_private_type_index_url(params[:person_id])
      index = {
        '@graph': [
          {
            '@id': id,
            '@type': ["solid:TypeIndex", "solid:ListedDocument"]
          },
          {
            '@id': "#{id}#reg1",
            '@type': "solid:TypeRegistration",
            'solid:forClass': "dfc-b:Organization",
            'solid:instanceContainer': organizations_url
          }
        ]
      }

      render(json: index, content_type: "application/ld+json")
    end

    private

    def user
      @user ||= Spree::User.find(params[:id])
    end

    def check_user_accessibility
      return if current_user == user

      not_found
    end
  end
end
