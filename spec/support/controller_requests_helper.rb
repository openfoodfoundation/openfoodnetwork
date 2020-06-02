# frozen_string_literal: true

require 'active_support/all'

module ControllerRequestsHelper
  def api_get(action, params = {}, session = nil, flash = nil)
    api_process(action, params, session, flash, "GET")
  end

  def api_post(action, params = {}, session = nil, flash = nil)
    api_process(action, params, session, flash, "POST")
  end

  def api_put(action, params = {}, session = nil, flash = nil)
    api_process(action, params, session, flash, "PUT")
  end

  def api_delete(action, params = {}, session = nil, flash = nil)
    api_process(action, params, session, flash, "DELETE")
  end

  def spree_get(action, parameters = nil, session = nil, flash = nil)
    process_spree_action(action, parameters, session, flash, "GET")
  end

  # Executes a request simulating POST HTTP method and set/volley the response
  def spree_post(action, parameters = nil, session = nil, flash = nil)
    process_spree_action(action, parameters, session, flash, "POST")
  end

  # Executes a request simulating PUT HTTP method and set/volley the response
  def spree_put(action, parameters = nil, session = nil, flash = nil)
    process_spree_action(action, parameters, session, flash, "PUT")
  end

  # Executes a request simulating DELETE HTTP method and set/volley the response
  def spree_delete(action, parameters = nil, session = nil, flash = nil)
    process_spree_action(action, parameters, session, flash, "DELETE")
  end

  private

  def api_process(action, params = {}, session = nil, flash = nil, method = "get")
    process_spree_action(action,
                         params.reverse_merge!(format: :json),
                         session,
                         flash,
                         method)
  end

  def process_spree_action(action, parameters = {}, session = nil, flash = nil, method = "GET")
    process(action,
            parameters.merge!(use_route: :spree),
            session,
            flash,
            method)
  end
end
