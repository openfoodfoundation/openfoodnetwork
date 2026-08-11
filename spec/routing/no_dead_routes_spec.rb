# frozen_string_literal: true

# `resources` and `resource` generate the full CRUD set by default, so routes
# whose action was never implemented - or was implemented once and later removed
# - pile up unnoticed. Nothing complains until somebody requests the URL and
# gets an AbstractController::ActionNotFound, or an ActionController::
# RoutingError when the controller class itself is missing.
#
# This spec walks every route in the application and in every mounted engine and
# checks that each one can actually be served: its controller either defines the
# action, or has a template that Rails will render implicitly.
RSpec.describe "route definitions" do
  # Dead routes we're deliberately keeping, each with the reason why. RSpec
  # fails a pending example that starts passing, so an entry here can't outlive
  # the route it excuses.
  known_dead_routes = {
    "GET /api/v1/enterprises/:id => api/v1/enterprises#show" =>
      "There is no Api::V1::EnterprisesController. Api::V1::CustomerSerializer " \
      "advertises this URL as the `related` link of a customer's enterprise " \
      "relationship, and it's covered by swagger/v1.yaml and " \
      "spec/requests/api/v1/customers_spec.rb, so the route can't just be " \
      "dropped. Either implement the endpoint or stop advertising the link.",
  }

  # Every route that names a controller and an action, following mounts into the
  # engines' own route sets. Redirects, Rack endpoints and routes with a dynamic
  # :action can't be checked statically, so they're skipped.
  collect_routes = lambda do |route_set, seen, collected|
    next collected unless seen.add?(route_set.object_id)

    mounted = []

    route_set.routes.each do |route|
      endpoint = route.app.respond_to?(:app) ? route.app.app : route.app

      if endpoint.respond_to?(:routes) && endpoint.routes.is_a?(ActionDispatch::Routing::RouteSet)
        mounted << endpoint.routes
        next
      end

      controller = route.defaults[:controller]
      action = route.defaults[:action]
      next if controller.blank? || action.blank?

      collected << {
        controller:,
        action:,
        description: "#{route.verb.presence || 'ANY'} " \
                     "#{route.path.spec.to_s.sub('(.:format)', '')} => " \
                     "#{controller}##{action}",
      }
    end

    mounted.each { |set| collect_routes.call(set, seen, collected) }

    collected
  end

  # How the route gets served, if at all. Note that `action_methods` includes
  # every public method on the controller, so a public helper that happens to
  # share a name with the action counts as served - this errs towards passing
  # rather than towards false alarms.
  served_by = lambda do |route|
    controller_class = "#{route[:controller].camelize}Controller".safe_constantize

    next :nothing unless controller_class.respond_to?(:action_methods)
    next :action if controller_class.action_methods.include?(route[:action])

    template = begin
      controller_class.new.lookup_context.exists?(
        route[:action], controller_class._prefixes, false
      )
    rescue StandardError
      false
    end

    template ? :template : :nothing
  end

  routes = collect_routes.call(Rails.application.routes, Set.new, []).uniq

  it "finds routes to check" do
    expect(routes.length).to be > 0
  end

  it "excuses only routes that still exist" do
    expect(known_dead_routes.keys - routes.pluck(:description)).to be_empty
  end

  routes.each do |route|
    it "serves #{route[:description]}" do
      pending known_dead_routes[route[:description]] if
        known_dead_routes.key?(route[:description])

      controller_class = "#{route[:controller].camelize}Controller"

      expect(served_by.call(route)).to be_in([:action, :template]),
                                       "#{route[:description]} can never be served: " \
                                       "#{controller_class} has no ##{route[:action]} " \
                                       "action and no template to render for it. " \
                                       "Constrain the route with `only:`/`except:`, " \
                                       "or implement the action."
    end
  end
end
