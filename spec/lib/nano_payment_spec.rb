# frozen_string_literal: true

require "bigdecimal"
require "nano_payment"

# These examples need nothing but the Ruby standard library:
#
#     rspec -O /dev/null -I lib spec/lib/nano_payment_spec.rb
RSpec.describe NanoPayment do
  # The published xno-binding v1 option C vector (BINDING-STANDARD.md).
  let(:burn) { "nano_1111111111111111111111111111111111111111111111111111hifc8npp" }
  let(:payer) { "nano_3t6k35gi95xu6tergt6p69ck76ogmitsa8mnijtpxm9fkcm736xtoncuohr3" }
  let(:raw) { 50_000_000_000_000_000_000_000_000_000 } # 0.05 XNO
  let(:bound_rep) { "nano_33q9dassq66es6mcay83n5kypqgpzjikr9bkc9ope9xch1borfphgehj4ozj" }

  describe NanoPayment::Blake2b do
    it "matches the RFC 7693 test vector" do
      expect(described_class.digest("abc", 64).unpack1("H*")).to eq(
        "ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d1" \
        "7d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923"
      )
    end

    it "hashes input longer than one block" do
      expect(described_class.digest("a" * 300, 32).bytesize).to eq 32
      expect(described_class.digest("a" * 300, 32)).not_to eq described_class.digest("a" * 299, 32)
    end

    it "refuses a digest length outside 1 to 64" do
      expect { described_class.digest("abc", 65) }.to raise_error(ArgumentError)
    end
  end

  describe NanoPayment::Address do
    it "decodes and encodes an account" do
      expect(described_class.public_key(burn)).to eq "0" * 64
      expect(described_class.from_public_key("0" * 64)).to eq burn
    end

    it "round-trips any key" do
      key = "D1E2F3A4B5C6D7E8F9A0B1C2D3E4F5A6B7C8D9E0F1A2B3C4D5E6F7A8B9C0D1E2"
      expect(described_class.public_key(described_class.from_public_key(key))).to eq key
    end

    it "refuses a wrong checksum" do
      expect(described_class.valid?(burn.sub(/p\z/, "q"))).to be false
    end

    it "refuses malformed input" do
      expect(described_class.valid?("nano_123")).to be false
      expect(described_class.valid?(nil)).to be false
      expect(described_class.valid?("btc_#{burn[5..]}")).to be false
    end

    it "treats xrb_ and nano_ as the same account" do
      expect(described_class.same_account?(burn, burn.sub("nano_", "xrb_"))).to be true
      expect(described_class.same_account?(burn, payer)).to be false
    end
  end

  describe NanoPayment::Amount do
    it "derives raw from XNO" do
      expect(described_class.xno_to_raw("0.05")).to eq raw
      expect(described_class.xno_to_raw("1")).to eq 10**30
      expect { described_class.xno_to_raw("0.#{'0' * 30}1") }.to raise_error(ArgumentError)
    end

    it "derives the raw owed from an order total and a price, without floats" do
      # 12.50 units at 3.2 XNO per unit = 40 XNO.
      expect(described_class.raw_for("12.50", "3.2")).to eq 40 * 10**30
      expect(described_class.raw_for(BigDecimal("0.1"), "0.3")).to eq 3 * 10**28
    end

    it "rounds a fraction of a raw up, never down" do
      expect(described_class.raw_for("1", "0.#{'0' * 30}1")).to eq 1
    end

    it "refuses a zero or negative price" do
      expect { described_class.raw_for("10", "0") }.to raise_error(ArgumentError)
      expect { described_class.raw_for("10", "-1") }.to raise_error(ArgumentError)
    end

    it "shows raw as an exact XNO decimal" do
      expect(described_class.raw_to_xno(raw)).to eq "0.05"
      expect(described_class.raw_to_xno(40 * 10**30)).to eq "40"
      expect(described_class.raw_to_xno(1)).to eq "0.#{'0' * 29}1"
    end

    it "recognises node raw strings only" do
      expect(described_class.raw?("50000000000000000000000000000")).to be true
      expect(described_class.raw?("1.5")).to be false
      expect(described_class.raw?("-1")).to be false
      expect(described_class.raw?(5)).to be false
    end
  end

  describe NanoPayment::Binding do
    it "reproduces the published option C vector" do
      expect(described_class.commitment_hex("order-0001", burn, raw)).to eq(
        "86e75a339b908cc926a478c1a0e5eb5dd6fc612c1d3251eb661faa78135c36cf"
      )
      expect(described_class.representative("order-0001", burn, raw)).to eq bound_rep
    end

    it "gives another payment or amount another representative" do
      expect(described_class.representative("order-0002", burn, raw)).not_to eq bound_rep
      expect(described_class.representative("order-0001", burn, raw + 1)).not_to eq bound_rep
    end
  end

  describe NanoPayment::Verifier do
    let(:created_at) { 1_763_200_000 }
    let(:block) {
      {
        "block_account" => payer,
        "amount" => raw.to_s,
        "confirmed" => "true",
        "subtype" => "send",
        "local_timestamp" => (created_at + 60).to_s,
        "contents" => { "link_as_account" => burn, "representative" => bound_rep },
      }
    }

    def verify(info)
      described_class.verify(info, pay_to: burn, raw:, representative: bound_rep,
                                   not_before: created_at)
    end

    def with_contents(changes)
      block.merge("contents" => block["contents"].merge(changes))
    end

    it "accepts a confirmed, bound send of the exact amount" do
      result = verify(block)
      expect(result).to be_ok
      expect(result.payer).to eq payer
    end

    it "refuses an unconfirmed send" do
      expect(verify(block.merge("confirmed" => "false")).error).to eq :not_confirmed
    end

    it "refuses a block that is not a send" do
      expect(verify(block.merge("subtype" => "receive")).error).to eq :not_a_send
    end

    it "refuses a send to another account" do
      expect(verify(with_contents("link_as_account" => payer)).error).to eq :wrong_destination
    end

    it "refuses an amount short or over by one raw" do
      expect(verify(block.merge("amount" => (raw - 1).to_s)).error).to eq :wrong_amount
      expect(verify(block.merge("amount" => (raw + 1).to_s)).error).to eq :wrong_amount
      expect(verify(block.merge("amount" => "5e28")).error).to eq :wrong_amount
    end

    it "refuses a send bound to another payment" do
      expect(verify(with_contents("representative" => burn)).error).to eq :not_bound
    end

    it "refuses a send the node saw before the payment existed" do
      expect(verify(block.merge("local_timestamp" => (created_at - 1).to_s)).error).to eq :too_old
      expect(verify(block.merge("local_timestamp" => "0")).error).to eq :too_old
    end

    it "refuses an empty reply" do
      expect(verify({})).not_to be_ok
      expect(verify(nil)).not_to be_ok
    end
  end

  describe NanoPayment::Node do
    let(:hash) { "A" * 64 }

    it "refuses a URL that is not http or https" do
      expect {
        described_class.new("ftp://node.example.org")
      }.to raise_error(described_class::Error)
      expect { described_class.new("") }.to raise_error(described_class::Error)
    end

    it "refuses a malformed block hash before any request" do
      node = described_class.new("https://node.example.org/rpc")
      expect(Net::HTTP).not_to receive(:start)
      expect { node.block_info("xyz") }.to raise_error(described_class::Error)
    end

    it "asks the node for the block as JSON" do
      reply = Net::HTTPOK.new("1.1", "200", "OK")
      allow(reply).to receive(:body).and_return('{"subtype":"send"}')
      http = instance_double(Net::HTTP)
      expect(http).to receive(:request) do |request|
        expect(JSON.parse(request.body)).to eq(
          "action" => "block_info", "json_block" => "true", "hash" => hash
        )
        reply
      end
      allow(Net::HTTP).to receive(:start)
        .with("node.example.org", 443, hash_including(use_ssl: true))
        .and_yield(http)

      node = described_class.new("https://node.example.org/rpc")
      expect(node.block_info(hash.downcase)).to eq("subtype" => "send")
    end

    it "raises on a node error reply" do
      reply = Net::HTTPOK.new("1.1", "200", "OK")
      allow(reply).to receive(:body).and_return('{"error":"Block not found"}')
      http = instance_double(Net::HTTP, request: reply)
      allow(Net::HTTP).to receive(:start).and_yield(http)

      node = described_class.new("https://node.example.org/rpc")
      expect { node.block_info(hash) }.to raise_error(described_class::Error, /Block not found/)
    end

    it "raises when the node cannot be reached" do
      allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED)

      node = described_class.new("https://node.example.org/rpc")
      expect { node.block_info(hash) }.to raise_error(described_class::Error)
    end
  end
end
