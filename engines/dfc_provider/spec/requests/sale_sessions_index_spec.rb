# frozen_string_literal: true

require_relative "../spec_helper"

# The swagger spec in sale_sessions_spec.rb documents the format of the
# response. These specs cover which cycles it selects, which price it reports
# and when it refuses to answer at all.
RSpec.describe "SaleSessions" do
  let(:user) { create(:oidc_user, email: "user@example.com") }
  let(:hub) { create(:distributor_enterprise, owner: user, name: "Hub") }
  let(:coordinator) { create(:distributor_enterprise, name: "Coordinator") }
  let(:producer) { create(:supplier_enterprise, name: "Producer") }
  let(:variant) { create(:variant, enterprise: producer, price: 10) }

  let(:order_cycle) {
    create(:simple_order_cycle, coordinator:, orders_open_at: 1.day.ago,
                                orders_close_at: 1.day.from_now)
  }

  # The hub receives the product of the producer through the coordinator.
  let!(:incoming_exchange) {
    create(:exchange, order_cycle:, sender: producer, receiver: coordinator, incoming: true,
                      variants: [variant])
  }
  let!(:outgoing_exchange) {
    create(:exchange, order_cycle:, sender: coordinator, receiver: hub, incoming: false,
                      variants: [variant])
  }

  let(:sale_sessions_url) { "/api/dfc/enterprises/#{hub.id}/sale_sessions" }

  before { login_as user }

  def create_cycle(distributor: hub, open: true)
    cycle = create(
      :simple_order_cycle, coordinator:,
                           orders_open_at: open ? 1.day.ago : 2.weeks.ago,
                           orders_close_at: open ? 1.day.from_now : 1.week.ago
    )
    create(:exchange, order_cycle: cycle, sender: coordinator, receiver: distributor,
                      incoming: false, variants: [variant])
    cycle
  end

  def add_producer_fee(amount)
    fee = create(:enterprise_fee, :per_item, enterprise: producer, amount:)
    ExchangeFee.create!(exchange: incoming_exchange, enterprise_fee: fee)
  end

  def add_coordinator_fee(amount)
    order_cycle.coordinator_fees << create(:enterprise_fee, :per_item, enterprise: coordinator,
                                                                       amount:)
  end

  def json
    JSON.parse(response.body) # rubocop:disable Rails/ResponseParsedBody
  end

  def nodes(type)
    Array.wrap(json["@graph"]).select { |node| node["@type"] == type }
  end

  def sale_sessions
    nodes("dfc-b:SaleSession")
  end

  def session_ids
    sale_sessions.map { |node| node["@id"] }
  end

  def session_url(cycle = order_cycle)
    "http://test.host/api/dfc/enterprises/#{hub.id}/sale_sessions/#{cycle.id}"
  end

  def offer(variant: self.variant)
    nodes("dfc-b:Offer").find { |node| node["@id"] == "#{session_url}/offers/#{variant.id}" }
  end

  def price_of(variant: self.variant)
    offer(variant:)["dfc-b:hasPrice"]["dfc-b:value"]
  end

  describe "listing the open order cycles" do
    it "returns one sale session per open cycle the enterprise distributes" do
      get sale_sessions_url

      expect(response).to have_http_status :ok
      expect(session_ids).to eq [session_url]
    end

    it "lists every open cycle of the enterprise" do
      second = create_cycle

      get sale_sessions_url

      expect(session_ids).to eq [session_url, session_url(second)]
    end

    it "returns the opening and closing dates of the cycle" do
      get sale_sessions_url

      expect(sale_sessions.first).to include(
        "dfc-b:beginDate" => SaleSessionBuilder.stringify_time(order_cycle.orders_open_at),
        "dfc-b:endDate" => SaleSessionBuilder.stringify_time(order_cycle.orders_close_at),
      )
    end

    it "doesn't list a cycle that has closed" do
      create_cycle(open: false)

      get sale_sessions_url

      expect(session_ids).to eq [session_url]
    end

    it "doesn't list a cycle that another enterprise distributes" do
      other = create(:distributor_enterprise, name: "Other hub")
      create_cycle(distributor: other)

      get sale_sessions_url

      expect(session_ids).to eq [session_url]
    end

    it "lists the offers of the variants it distributes" do
      get sale_sessions_url

      expect(sale_sessions.first["dfc-b:lists"]).to eq "#{session_url}/offers/#{variant.id}"
      expect(offer["dfc-b:offeredItem"]).to eq(
        "http://test.host/api/dfc/enterprises/#{producer.id}/supplied_products/#{variant.id}"
      )
    end

    it "doesn't list the offer of a variant the cycle doesn't carry" do
      other_variant = create(:variant, enterprise: producer, price: 10)

      get sale_sessions_url

      expect(offer(variant: other_variant)).to be_nil
    end

    it "reports the stock available" do
      variant.update!(on_hand: 7)

      get sale_sessions_url

      expect(offer["dfc-b:stockLimitation"]).to eq 7
    end
  end

  describe "the price of an offer" do
    it "is the price of the variant without enterprise fees" do
      get sale_sessions_url

      expect(price_of).to eq 10
    end

    it "adds a per-item fee of the exchange" do
      add_producer_fee(1.5)

      get sale_sessions_url

      expect(price_of).to eq 11.5
    end

    it "takes a negative fee off the price" do
      add_producer_fee(-2)

      get sale_sessions_url

      expect(price_of).to eq 8
    end

    it "adds the coordinator's fees" do
      add_coordinator_fee(3)

      get sale_sessions_url

      expect(price_of).to eq 13
    end

    it "sums the fees of the exchange and of the coordinator" do
      add_producer_fee(1.5)
      add_coordinator_fee(3)

      get sale_sessions_url

      expect(price_of).to eq 14.5
    end

    it "uses the price that the distributor overrides", feature: :inventory do
      create(:variant_override, hub:, variant:, price: 20)
      add_producer_fee(1.5)

      get sale_sessions_url

      expect(price_of).to eq 21.5
    end
  end

  describe "listing as a platform user" do
    let(:enterprise_id) { hub.id }
    let(:access_token) { allow_token_for(client_id: ApiUser.platform_url("cqcm-dev")) }
    let(:headers) { { "Authorization" => "Bearer #{access_token}" } }

    def grant_permission(scope)
      DfcPermission.create!(user:, enterprise_id:, scope:, grantee: "cqcm-dev")
    end

    it "requires the ReadProducts scope" do
      grant_permission("ReadEnterprise")

      get sale_sessions_url, headers: headers

      expect(response).to have_http_status :unauthorized
    end

    it "lists the cycles with the ReadProducts scope" do
      grant_permission("ReadEnterprise")
      grant_permission("ReadProducts")

      get sale_sessions_url, headers: headers

      expect(response).to have_http_status :ok
      expect(session_ids).to eq [session_url]
    end

    it "requires the ReadProducts scope to show one session" do
      grant_permission("ReadEnterprise")

      get "#{sale_sessions_url}/#{order_cycle.id}", headers: headers

      expect(response).to have_http_status :unauthorized
    end
  end

  describe "refusing to list" do
    it "returns 404 for an enterprise the user doesn't manage" do
      other = create(:distributor_enterprise, name: "Other hub")

      get "/api/dfc/enterprises/#{other.id}/sale_sessions"

      expect(response).to have_http_status :not_found
    end

    it "returns 401 without a login" do
      login_as nil

      get sale_sessions_url

      expect(response).to have_http_status :unauthorized
    end
  end

  describe "showing one sale session" do
    it "returns the session with its offers" do
      get "#{sale_sessions_url}/#{order_cycle.id}"

      expect(response).to have_http_status :ok
      expect(session_ids).to eq [session_url]
      expect(price_of).to eq 10
    end

    it "returns 404 for a cycle that this enterprise doesn't distribute" do
      other = create(:distributor_enterprise, name: "Other hub")
      cycle = create_cycle(distributor: other)

      get "#{sale_sessions_url}/#{cycle.id}"

      expect(response).to have_http_status :not_found
    end

    it "returns 404 for a closed cycle" do
      cycle = create_cycle(open: false)

      get "#{sale_sessions_url}/#{cycle.id}"

      expect(response).to have_http_status :not_found
    end
  end

  describe "in DFC v2 format" do
    let(:v2_headers) { { "Accept" => 'application/ld+json; profile="dfc-v2"' } }

    it "lists the sessions in a container" do
      get sale_sessions_url, headers: v2_headers

      container = nodes("ldp:Container").first

      expect(container["ldp:contains"]).to eq session_url
      expect(sale_sessions.first["dfc-b:lists"]).to eq "#{session_url}/offers/#{variant.id}"
      expect(price_of).to eq 10
    end
  end
end
