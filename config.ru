# This file is used by Rack-based servers to start the application.

# Use Out-Of-Bounds Garbage Collection to improve memory cleanup
# See: http://tmm1.net/ruby21-oobgc/ for details
if ENV.fetch("USE_OOBGC", false) && (Rails.env.production? || Rails.env.staging?)
  require 'gctools/oobgc'

  use GC::OOB::UnicornMiddleware
end

require ::File.expand_path('../config/environment', __FILE__)
run Openfoodnetwork::Application
