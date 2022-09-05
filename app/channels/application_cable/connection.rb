# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :session_id, :current_user

    def connect
      # initializes Warden after a cold start, in case you're visitor #1
      env["warden"].authenticated?
      # the problem with only using session is that users often login on multiple devices
      self.current_user = env["warden"].user
      # the problem with only using user is that sometimes you might want to use SR before you login
      self.session_id = request.session.id
      # and so, we recommend using both

      # this assumes that you want to enable SR for unauthenticated users
      reject_unauthorized_connection unless current_user || session_id

      # if you want to disable SR for unauthenticated users,
      # comment out the line above and uncomment the line below
      # reject_unauthorized_connection unless current_user
    end
  end
end
