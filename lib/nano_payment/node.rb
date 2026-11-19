# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module NanoPayment
  # Reads one block from a Nano node's JSON RPC. It only reads: there is no
  # key, no seed and no wallet call anywhere in this code.
  class Node
    class Error < StandardError; end

    HASH = /\A\h{64}\z/

    def initialize(url, timeout: 10)
      @uri = URI.parse(url.to_s)
      raise Error, "The Nano node URL must be http or https" unless
        @uri.is_a?(URI::HTTP) && !@uri.host.to_s.empty?

      @timeout = timeout
    end

    # The node's `block_info` reply as a Hash.
    def block_info(hash)
      raise Error, "Not a Nano block hash" unless HASH.match?(hash.to_s)

      reply = post(action: "block_info", json_block: "true", hash: hash.upcase)
      raise Error, "The Nano node answered: #{reply['error']}" if reply.key?("error")

      reply
    end

    private

    def post(payload)
      request = Net::HTTP::Post.new(@uri, "Content-Type" => "application/json")
      request.body = JSON.generate(payload)
      response = Net::HTTP.start(@uri.host, @uri.port, use_ssl: @uri.scheme == "https",
                                                       open_timeout: @timeout,
                                                       read_timeout: @timeout) do |http|
        http.request(request)
      end
      raise Error, "The Nano node answered HTTP #{response.code}" unless
        response.is_a?(Net::HTTPSuccess)

      parsed = JSON.parse(response.body)
      raise Error, "The Nano node did not answer with an object" unless parsed.is_a?(Hash)

      parsed
    rescue JSON::ParserError, SystemCallError, IOError, Timeout::Error, SocketError => e
      raise Error, "The Nano node could not be read: #{e.class}"
    end
  end
end
