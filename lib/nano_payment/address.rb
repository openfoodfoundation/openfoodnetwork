# frozen_string_literal: true

require_relative "blake2b"

module NanoPayment
  # Nano account addresses: `nano_` + 52 characters of key + 8 of checksum,
  # in Nano's own base32 alphabet. The checksum is a 5-byte BLAKE2b of the
  # public key, byte-reversed.
  module Address
    ALPHABET = "13456789abcdefghijkmnopqrstuwxyz"
    FORMAT = /\A(?:nano|xrb)_([13][13-9a-km-uw-z]{59})\z/

    module_function

    def valid?(address)
      !public_key(address).nil?
    end

    # The public key as uppercase hex, or nil if the address is malformed or
    # its checksum does not match.
    def public_key(address)
      match = FORMAT.match(address.to_s.strip)
      return nil unless match

      number = match[1].each_char.reduce(0) { |acc, char| (acc << 5) | ALPHABET.index(char) }
      key = [(number >> 40).to_s(16).rjust(64, "0")].pack("H*")
      checksum = number & 0xFFFFFFFFFF

      return nil unless checksum_of(key) == checksum

      key.unpack1("H*").upcase
    end

    # Encodes a 32-byte public key given as hex into its `nano_` address.
    def from_public_key(hex)
      raise ArgumentError, "A Nano public key is 64 hex characters" unless
        hex.to_s.match?(/\A\h{64}\z/)

      key = [hex].pack("H*")
      number = (hex.to_i(16) << 40) | checksum_of(key)
      encoded = Array.new(60) { |i| ALPHABET[(number >> (5 * (59 - i))) & 31] }.join

      "nano_#{encoded}"
    end

    # Two addresses match when they encode the same key (`xrb_` and `nano_`
    # forms of one account are the same account).
    def same_account?(first, second)
      key = public_key(first)
      !key.nil? && key == public_key(second)
    end

    def checksum_of(key)
      Blake2b.digest(key, 5).reverse.unpack1("H*").to_i(16)
    end
  end
end
