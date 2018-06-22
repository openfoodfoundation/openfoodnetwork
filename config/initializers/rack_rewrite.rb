module Openfoodnetwork
  class Application < Rails::Application
    config.middleware.insert_before(Rack::Lock, Rack::Rewrite) do
      r301   '/admin/products/bulk_edit',  '/admin/products' # TODO: Date added 15/06/2018
    end
  end
end
