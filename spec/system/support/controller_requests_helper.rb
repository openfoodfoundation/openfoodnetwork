# frozen_string_literal: true

require 'active_support/all'

module ControllerRequestsHelper
  def api_get(action, params = {}, session = nil, flash = nil)
    process_json_action(action, params, session, flash, "GET")
  end

  def api_post(action, params = {}, session = nil, flash = nil)
    process_json_action(action, params, session, flash, "POST")
  end

  def api_put(action, params = {}, session = nil, flash = nil)
    process_json_action(action, params, session, flash, "PUT")
  end

  def api_delete(action, params = {}, session = nil, flash = nil)
    process_json_action(action, params, session, flash, "DELETE")
  end

  def spree_get(action, params = {}, session = nil, flash = nil)
    process_action_with_route(action, params, session, flash, "GET")
  end

  def spree_post(action, params = {}, session = nil, flash = nil)
    process_action_with_route(action, params, session, flash, "POST")
  end

  def spree_put(action, params = {}, session = nil, flash = nil)
    process_action_with_route(action, params, session, flash, "PUT")
  end

  def spree_delete(action, params = {}, session = nil, flash = nil)
    process_action_with_route(action, params, session, flash, "DELETE")
  end

  private

  def process_json_action(action, params = {}, session = nil, flash = nil, method = "get")
    process_action_with_route(action,
                              params.reverse_merge!(format: :json),
                              session,
                              flash,
                              method)
  end

  def process_action_with_route(action, params = {}, session = nil, flash = nil, method = "GET")
    process(action,
            method: method,
            params: params.reverse_merge!(use_route: :main_app),
            session: session,
            flash: flash)
  end
end
