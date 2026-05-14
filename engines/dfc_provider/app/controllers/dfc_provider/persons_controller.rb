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
      prefs = {
        '@graph': [
          {
            '@id': id,
            '@type': "pim:ConfigurationFile",
          },
          {
            '@id': "#{webid}#me",
            'solid:privateTypeIndex': "TBC"
          }
        ]
      }

      render(json: prefs, content_type: "application/ld+json")
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
