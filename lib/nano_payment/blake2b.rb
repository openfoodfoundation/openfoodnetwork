# frozen_string_literal: true

module NanoPayment
  # BLAKE2b (RFC 7693) with a variable digest length, in plain Ruby.
  #
  # Nano needs a 5-byte BLAKE2b for the address checksum. OpenSSL only exposes
  # the 64-byte variant to Ruby, so this small implementation keeps the Nano
  # code free of any extra gem.
  module Blake2b
    MASK = 0xFFFFFFFFFFFFFFFF

    IV = [
      0x6A09E667F3BCC908, 0xBB67AE8584CAA73B, 0x3C6EF372FE94F82B, 0xA54FF53A5F1D36F1,
      0x510E527FADE682D1, 0x9B05688C2B3E6C1F, 0x1F83D9ABFB41BD6B, 0x5BE0CD19137E2179,
    ].freeze

    SIGMA = [
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
      [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
      [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
      [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
      [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
      [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
      [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
      [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
      [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
      [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0],
    ].freeze

    BLOCK_BYTES = 128

    module_function

    # Returns the binary digest of `data` with `length` bytes (1 to 64).
    def digest(data, length)
      raise ArgumentError, "BLAKE2b length must be 1 to 64 bytes" unless (1..64).cover?(length)

      data = data.b
      h = IV.dup
      h[0] ^= 0x01010000 ^ length

      blocks = (0...[data.bytesize, 1].max).step(BLOCK_BYTES).map do |offset|
        data.byteslice(offset, BLOCK_BYTES)
      end
      counter = 0
      blocks.each_with_index do |block, index|
        counter += block.bytesize
        padded = block.ljust(BLOCK_BYTES, "\0")
        compress(h, padded, counter, index == blocks.size - 1)
      end

      h.pack("Q<8").byteslice(0, length)
    end

    def compress(h, block, counter, final)
      m = block.unpack("Q<16")
      v = h + IV
      v[12] ^= counter & MASK
      v[13] ^= (counter >> 64) & MASK
      v[14] ^= MASK if final

      12.times do |round|
        s = SIGMA[round % 10]
        mix(v, 0, 4, 8, 12, m[s[0]], m[s[1]])
        mix(v, 1, 5, 9, 13, m[s[2]], m[s[3]])
        mix(v, 2, 6, 10, 14, m[s[4]], m[s[5]])
        mix(v, 3, 7, 11, 15, m[s[6]], m[s[7]])
        mix(v, 0, 5, 10, 15, m[s[8]], m[s[9]])
        mix(v, 1, 6, 11, 12, m[s[10]], m[s[11]])
        mix(v, 2, 7, 8, 13, m[s[12]], m[s[13]])
        mix(v, 3, 4, 9, 14, m[s[14]], m[s[15]])
      end

      8.times { |i| h[i] ^= v[i] ^ v[i + 8] }
    end

    def mix(v, a, b, c, d, x, y)
      v[a] = (v[a] + v[b] + x) & MASK
      v[d] = rotr(v[d] ^ v[a], 32)
      v[c] = (v[c] + v[d]) & MASK
      v[b] = rotr(v[b] ^ v[c], 24)
      v[a] = (v[a] + v[b] + y) & MASK
      v[d] = rotr(v[d] ^ v[a], 16)
      v[c] = (v[c] + v[d]) & MASK
      v[b] = rotr(v[b] ^ v[c], 63)
    end

    def rotr(value, bits)
      ((value >> bits) | (value << (64 - bits))) & MASK
    end
  end
end
