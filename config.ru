# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

if ENV.fetch('KILL_UNICORNS', false) && ['production', 'staging'].include?(ENV['RAILS_ENV'])
  # Gracefully restart individual unicorn workers if they have:
  # - performed between 25000 and 30000 requests
  # - grown in memory usage to between 700 and 850 MB
  require 'unicorn/worker_killer'
  use Unicorn::WorkerKiller::MaxRequests,
      ENV.fetch('UWK_REQS_MIN', 25_000).to_i,
      ENV.fetch('UWK_REQS_MAX', 30_000).to_i
  use Unicorn::WorkerKiller::Oom,
      ( ENV.fetch('UWK_MEM_MIN', 700).to_i * (1024**2) ),
      ( ENV.fetch('UWK_MEM_MAX', 850).to_i * (1024**2) )
end

require ::File.expand_path('config/environment', __dir__)
run Openfoodnetwork::Application
