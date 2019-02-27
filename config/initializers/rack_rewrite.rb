module Openfoodnetwork
  class Application < Rails::Application
    config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
      r301 '/admin/products/bulk_edit', '/admin/products'
    end
  end
end
