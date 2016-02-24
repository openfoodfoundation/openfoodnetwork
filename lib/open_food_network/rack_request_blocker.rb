# Copied from http://blog.salsify.com/engineering/tearing-capybara-ajax-tests
# https://gist.github.com/jturkel/9317269/raw/ff7838684370fd8a468ffe1e5ce1f3e46ba39951/rack_request_blocker.rb

require 'atomic'

# Rack middleware that keeps track of the number of active requests and can block new requests.
class RackRequestBlocker

  @@num_active_requests = Atomic.new(0)
  @@block_requests = Atomic.new(false)

  # Returns the number of requests the server is currently processing.
  def self.num_active_requests
    @@num_active_requests.value
  end

  # Prevents the server from accepting new requests. Any new requests will return an HTTP
  # 503 status.
  def self.block_requests!
    @@block_requests.value = true
  end

  # Allows the server to accept requests again.
  def self.allow_requests!
    @@block_requests.value = false
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    increment_active_requests
    if block_requests?
      block_request(env)
    else
      @app.call(env)
    end
  ensure
    decrement_active_requests
  end

  def self.wait_for_requests_complete
    self.block_requests!
    max_wait_time = 30
    polling_interval = 0.01
    wait_until = Time.now + max_wait_time.seconds
    while true
      return if self.num_active_requests == 0
      if Time.now > wait_until
        raise "Failed waiting for completing requests, #{self.num_active_requests} running."
      else
        sleep(polling_interval)
      end
    end
  ensure
    self.allow_requests!
  end

  private

  def block_requests?
    @@block_requests.value
  end

  def block_request(env)
    [503, {}, []]
  end

  def increment_active_requests
    @@num_active_requests.update { |v| v + 1 }
  end

  def decrement_active_requests
    @@num_active_requests.update { |v| v - 1 }
  end
end
