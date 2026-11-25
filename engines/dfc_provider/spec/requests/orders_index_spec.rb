# frozen_string_literal: true

require_relative "../spec_helper"

# The swagger spec in orders_spec.rb documents the format of the index
# response. These specs cover which orders it selects, and which it refuses to
# return at all.
RSpec.describe "Orders index" do
  let(:user) { create(:oidc_user, email: "user@example.com") }
  let(:enterprise) { create(:distributor_enterprise, owner: user) }
  let(:variant) { create(:variant, enterprise:, on_demand: false, on_hand: 10) }
  let(:orders_url) { "/api/dfc/enterprises/#{enterprise.id}/orders" }
  let(:v2_headers) { { "Accept" => 'application/ld+json; profile="dfc-v2"' } }

  before { login_as user }

  def create_order(distributor: enterprise, variant: self.variant)
    create(
      :completed_order_with_totals, :with_line_item,
      line_items_count: 0, distributor:, variant:,
    )
  end

  def order_url(order)
    "http://test.host/api/dfc/enterprises/#{order.distributor_id}/orders/#{order.id}"
  end

  # Rails doesn't parse `application/ld+json` responses (see the "JSON LD"
  # shared context), so we read the DFC v2 body ourselves as well.
  def response_json
    JSON.parse(response.body) # rubocop:disable Rails/ResponseParsedBody
  end

  def graph
    response_json.fetch("@graph")
  end

  def listed_orders
    graph.select { |node| node["@type"] == "dfc-b:Order" }
  end

  def listed_order_ids
    listed_orders.map { |node| node["@id"] }
  end

  # A container with members is serialised next to them in a graph, and one
  # without members is the whole response.
  def container
    (response_json["@graph"] || [response_json]).find do |node|
      node["@type"] == "ldp:Container"
    end
  end

  describe "listing the orders of an enterprise" do
    it "returns the orders of this enterprise" do
      order = create_order

      get orders_url

      expect(response).to have_http_status :ok
      expect(listed_order_ids).to eq [order_url(order)]
    end

    it "returns all the orders of this enterprise" do
      first = create_order
      second = create_order

      get orders_url

      expect(listed_order_ids).to eq [order_url(first), order_url(second)]
    end

    it "returns the same DFC subjects as the show action" do
      order = create_order

      get orders_url

      expect(listed_order_ids).to eq [order_url(order)]
      expect(graph.pluck("@type")).to include(
        "dfc-b:OrderLine", "dfc-b:Offer", "dfc-b:SuppliedProduct", "dfc-b:SaleSession"
      )
    end

    it "returns each offer once when orders share a product" do
      create_order
      create_order

      get orders_url

      offers = graph.select { |node| node["@type"] == "dfc-b:Offer" }
      expect(offers.count).to eq 1
    end

    it "doesn't return a cart that nobody has placed" do
      order = create_order
      cart = create(:order, distributor: enterprise)

      get orders_url

      expect(enterprise.distributed_orders).to include cart
      expect(listed_order_ids).to eq [order_url(order)]
    end

    it "returns an empty body without orders" do
      get orders_url

      expect(response).to have_http_status :ok
      expect(response.body).to be_empty
    end

    it "defaults to the DFC 1.16 profile" do
      create_order

      get orders_url

      expect(response_json).to include(
        "@context" => "https://w3id.org/dfc/ontology/context/context_1.16.0.json"
      )
    end

    it "returns a container in the DFC v2 profile" do
      first = create_order
      second = create_order

      get orders_url, headers: v2_headers

      expect(container["@type"]).to eq "ldp:Container"
      expect(Array.wrap(container["ldp:contains"])).to eq [order_url(first), order_url(second)]
      expect(response.content_type).to include "dfc-v2"
    end

    it "returns an empty container in the DFC v2 profile without orders" do
      get orders_url, headers: v2_headers

      expect(response).to have_http_status :ok
      expect(container["@type"]).to eq "ldp:Container"
    end
  end

  describe "selecting the orders of the current enterprise" do
    it "doesn't return the orders of another enterprise" do
      order = create_order
      other_enterprise = create(:enterprise)
      create_order(
        distributor: other_enterprise,
        variant: create(:variant, enterprise: other_enterprise),
      )

      get orders_url

      expect(listed_order_ids).to eq [order_url(order)]
    end

    it "doesn't allow reading the orders of another enterprise" do
      other_enterprise = create(:enterprise)

      get "/api/dfc/enterprises/#{other_enterprise.id}/orders"

      expect(response).to have_http_status :not_found
      expect(response.body).to be_empty
    end
  end

  describe "pagination" do
    it "returns one page at a time" do
      orders = Array.new(3) { create_order }

      get orders_url, params: { page: 1, per_page: 2 }
      expect(listed_order_ids).to eq [order_url(orders[0]), order_url(orders[1])]

      get orders_url, params: { page: 2, per_page: 2 }
      expect(listed_order_ids).to eq [order_url(orders[2])]
    end

    it "starts at the first page without a page number" do
      orders = Array.new(3) { create_order }

      get orders_url, params: { per_page: 2 }

      expect(listed_order_ids).to eq [order_url(orders[0]), order_url(orders[1])]
    end

    it "returns an empty page past the last order" do
      create_order

      get orders_url, params: { page: 2 }

      expect(response).to have_http_status :ok
      expect(response.body).to be_empty
    end
  end

  describe "filtering by update time" do
    it "returns only the orders updated since the given time" do
      old_order = create_order
      old_order.update_columns(updated_at: 2.days.ago)
      recent_order = create_order

      get orders_url, params: { updated_since: 1.day.ago.iso8601 }

      expect(listed_order_ids).to eq [order_url(recent_order)]
    end

    it "refuses an update time it can't read" do
      create_order

      get orders_url, params: { updated_since: "not-a-date" }

      expect(response).to have_http_status :bad_request
      expect(response.body).to be_empty
    end
  end

  describe "permissions" do
    include_context "authenticated as platform"

    let(:headers) { { "Authorization" => "Bearer #{access_token}" } }

    before do
      DfcPermission.create!(user:, enterprise:, scope: "ReadEnterprise", grantee: "cqcm-dev")
    end

    it "lists the orders with the ReadOrders scope" do
      order = create_order
      DfcPermission.create!(user:, enterprise:, scope: "ReadOrders", grantee: "cqcm-dev")

      get orders_url, headers: headers

      expect(response).to have_http_status :ok
      expect(listed_order_ids).to eq [order_url(order)]
    end

    it "refuses to list orders with the ReadEnterprise scope only" do
      create_order

      get orders_url, headers: headers

      expect(response).to have_http_status :unauthorized
      expect(response.body).to be_empty
    end

    it "refuses to list orders of an enterprise it can't read" do
      other_enterprise = create(:enterprise)

      get "/api/dfc/enterprises/#{other_enterprise.id}/orders", headers: headers

      expect(response).to have_http_status :not_found
      expect(response.body).to be_empty
    end

    it "doesn't list the orders of an enterprise it has no ReadOrders scope for" do
      other_enterprise = create(:enterprise)
      DfcPermission.create!(
        user:, enterprise: other_enterprise, scope: "ReadEnterprise", grantee: "cqcm-dev"
      )
      DfcPermission.create!(user:, enterprise:, scope: "ReadOrders", grantee: "cqcm-dev")
      create_order
      create_order(
        distributor: other_enterprise,
        variant: create(:variant, enterprise: other_enterprise),
      )

      get orders_url, headers: headers

      expect(listed_order_ids).to eq [order_url(enterprise.distributed_orders.first)]
    end
  end
end
