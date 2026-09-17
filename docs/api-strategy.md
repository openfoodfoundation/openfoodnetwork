# OFN API Strategy: DFC first, V1 for the gap

> **Status:** draft for cohort review — June 2026
> **Scope:** complements `AGENTS-api.md`. Establishes the strategic position on which API layer owns which resources, and why.

---

## The question

OFN has two active, non-deprecated API layers: the DFC provider (`engines/dfc_provider/`, JSON-LD, semantic web) and V1 (`app/controllers/api/v1/`, standard Rails REST/JSON). A common instinct is to treat them as serving separate audiences — DFC for platform-to-platform federation, V1 for hub-manager-to-tools operational integration — and develop them in parallel.

This document argues for a different split: **use DFC wherever the standard covers the resource; use V1 only for what falls outside DFC's scope.** The two APIs are not parallel tracks. DFC is the primary layer; V1 is the residual one.

---

## Why DFC first

### The consumption-complexity objection no longer holds

The traditional argument against DFC for operational integrations is that JSON-LD is hard to consume from automation tools like n8n, Zapier, or ERP connectors. Those tools expect flat REST/JSON, not semantic graphs with `@context` and IRI-namespaced properties.

This objection weakens substantially in a workflow where LLMs build integrations from API specs. Given a well-formed OpenAPI/YAML spec, an LLM generates a working n8n workflow or ERP connector against DFC just as readily as against V1. The JSON-LD structure is the LLM's problem to handle, not the hub manager's. What matters to the hub manager is what data is available and whether the spec accurately documents it.

The consumption argument was always about human developers reading raw wire responses. In an LLM-assisted integration workflow, that is increasingly not the dominant path.

### A single API surface has real maintenance advantages

Two APIs covering the same resource — say, products in DFC and products in V1 — means two serializers to keep in sync, two auth paths to audit, two sets of docs to update when the data model changes. Every resource that lives in exactly one layer is one fewer synchronization problem.

### DFC is already further along than it looks

The DFC engine already has routed, working endpoints for enterprises, products, catalog items (variants with per-hub stock and pricing), offers, addresses, persons, enterprise groups, product groups, and social media. Beyond what's routed, builders for `Order`, `OrderLine`, and `SaleSession` (order cycles) already exist in the engine — they map OFN records to DFC concepts and are used internally for the affiliate sales data endpoint. The data modelling work has already been done; those concepts just need routing.

### DFC participation has value beyond OFN

DFC is a community standard. Exposing OFN data through it means OFN instances can federate with FarmOS, Katuma, La Ruche Qui Dit Oui, and any other platform that speaks the protocol — without custom integration work on either side. Building operational endpoints in V1 instead of DFC keeps that interoperability locked out of the parts of OFN that need it most (order data, sales reporting inputs).

---

## Pros and cons

### Pros of DFC first

- **Reduces long-term API surface.** Fewer endpoints to maintain, document, and test when one layer owns each resource.
- **Interoperability by default.** Any endpoint built in DFC is immediately usable by other DFC-participant platforms, not just OFN's own integrations.
- **Semantic richness.** DFC's ontology carries meaning that plain REST/JSON doesn't — product types, quantity units, certification status — which makes integrations more robust and less brittle to field name changes.
- **Existing infrastructure.** Auth, serialization patterns, and the DFC connector library are already established in the engine. New endpoints follow a clear pattern.
- **LLM-friendly by spec.** A well-documented DFC API (YAML spec) is as LLM-friendly as V1. The spec is the interface, not the wire format.
- **Alignment with the DFC standard limits local drift.** When DFC evolves, OFN benefits from upstream improvements. Building the same thing privately in V1 creates a local fork that drifts.

### Cons / risks of DFC first

- **DFC standard coverage has gaps.** Reports, variant overrides, subscriptions, payment workflows, and order cycle management have no DFC concept. Forcing them into DFC would require either extending the standard (slow) or creating OFN-specific vocabulary (a fork in practice). These genuinely belong in V1.
- **Upstream coordination takes time.** Where OFN needs DFC to cover something it doesn't today (richer SaleSession fields, order filtering patterns), that requires proposing changes to the DFC consortium. This is not always fast.
- **DFC's endpoint patterns are less flexible for operational queries.** Hub managers need to filter orders by date range, order cycle, fulfilment status — query patterns that don't map cleanly onto DFC's resource-oriented structure. Some V1 complement may be needed even where DFC owns the data model.
- **JSON-LD has a debugging cost.** Even if LLMs generate integration code, developers debugging a failing integration still read raw responses. JSON-LD with nested `@context` resolution is harder to trace in a browser network panel or n8n log than flat JSON. This is a friction point, not a blocker.

---

## The split

### DFC API — owns these resources

The DFC engine already exposes these. Do not duplicate them in V1.

| OFN resource | DFC concept | Current DFC status |
|---|---|---|
| Enterprises (hubs, producers) | `dfc-b:Enterprise` | ✅ Routed — `GET /enterprises`, `GET /enterprises/:id` |
| Products / variants | `dfc-b:SuppliedProduct` | ✅ Routed — `GET/POST/PUT /enterprises/:id/supplied_products` |
| Catalog items (variant + per-hub stock) | `dfc-b:CatalogItem` | ✅ Routed — `GET/PUT /enterprises/:id/catalog_items` |
| Pricing | `dfc-b:Offer` | ✅ Routed — `GET/PUT /enterprises/:id/offers` |
| Addresses | address | ✅ Routed — `GET /addresses/:id` |
| Users / persons | `dfc-b:Person` | ✅ Routed — `GET /persons/:id` |
| Product groups / categories | `dfc-b:ProductGroup` | ✅ Routed — `GET /product_groups/:id` |
| Enterprise groups | `dfc-b:EnterpriseGroup` | ✅ Routed — `GET /enterprise_groups` |
| Social media links | `dfc-b:SocialMedia` | ✅ Routed — `GET /enterprises/:id/social_medias` |
| Platform connections | — | ✅ Routed — `GET/PUT /enterprises/:id/platforms` |
| Inbound platform events (from other platforms) | — | ✅ Routed — `POST /events` |
| Aggregate affiliate sales data | — | ✅ Routed — `GET /affiliate_sales_data` |

#### DFC concepts already modelled, not yet routed — extend DFC here, not V1

`OrderBuilder`, `OrderLineBuilder`, and `SaleSessionBuilder` exist in the engine and map OFN records to DFC types. They are used internally but not exposed as endpoints. These should be wired up in DFC rather than built as parallel V1 endpoints.

| OFN resource | DFC concept | Current status | Notes |
|---|---|---|---|
| Orders (read) | `dfc-b:Order` | Builder exists, not routed | Index/show scoped to managed enterprises |
| Line items (read) | `dfc-b:OrderLine` | Builder exists, not routed | Nested under orders |
| Order cycles (read) | `dfc-b:SaleSession` | Builder exists, not routed | `SaleSessionBuilder` already maps `orders_open_at`/`orders_close_at`; expose index/show scoped to managed enterprises |

**Caveat on order cycles:** `dfc-b:SaleSession` captures the temporal window and coordinator. The full OFN order cycle — exchanges, enterprise fees, distributor and producer lists, subscription sync — has no DFC equivalent beyond that. Read access via DFC is straightforward; creation and management belong in V1.

---

### V1 API — owns these resources

These have no DFC standard concept. They belong in V1 without qualification.

| Resource | Reason |
|---|---|
| **Reports** (packing, sales tax, xero invoices, revenues_by_hub, etc.) | OFN-specific operational reporting. No DFC concept. Primary unblock for n8n/ERP workflows. |
| **Order cycle create / clone / update** | `CloneService` and the full exchange/fee/subscription sync structure are OFN-specific. `dfc-b:SaleSession` is a data type, not a management API. |
| **Variant overrides** | Hub-level price and stock overrides per producer variant. No DFC concept. |
| **Customers** (OFN customer records) | OFN's customer model (per-enterprise records, tags, balance) is distinct from `dfc-b:Person` which represents a platform user. |
| **Customer account transactions** | OFN credit/balance system. No DFC equivalent. |
| **Subscriptions** | Recurring orders with OFN-specific scheduling, proxy orders, and subscription coordination. No DFC concept. |
| **Payments** | OFN payment methods, payment workflow, and the planned payment-due webhook + update endpoint (issue #14406). No DFC equivalent. |
| **Outbound webhooks** | OFN's webhook delivery infrastructure (`order_cycle_opened`, `payment_status_changed`, planned `payment_due`). OFN infrastructure, not a DFC data concept. |
| **Pickup / delivery logistics** | `pickup_time`, `pickup_instructions`, `receival_instructions` live on the `exchanges` table. No DFC concept. |

---

## Grey areas and decision rules

### Orders: DFC for the resource, V1 complement for complex queries

`dfc-b:Order` covers the order entity cleanly. But filtering orders by date range, order cycle, fulfilment status, and distributor — the queries hub managers actually need — does not map onto DFC's resource-oriented endpoint pattern. **Rule:** expose orders as a DFC resource; if operational query needs exceed what DFC's structure supports cleanly, add a V1 `GET /api/v1/orders` with filtering. Do not duplicate the data model — the V1 query endpoint uses the same underlying data, just with a different interface.

### Order cycles: DFC for read, V1 for write

Expose `GET /dfc/enterprises/:id/sale_sessions` for read using `SaleSessionBuilder`. Keep `POST /api/v1/order_cycles` (clone/create via `CloneService`) in V1. Management is OFN-specific; read access is not.

### Customers: V1 for now, revisit if DFC extends

OFN's customer entity carries OFN-specific fields (enterprise scope, balance, tags) that don't fit `dfc-b:Person`. Keep in V1. Revisit if the DFC standard adds a customer-relationship concept.

---

## Decision rule for new endpoints

When scoping any new endpoint, ask in order:

1. **Does DFC have a concept for this resource?** → Build in DFC.
2. **Does DFC partially cover it?** → Build what DFC covers in DFC; put the OFN-specific remainder in V1.
3. **Is it purely OFN-specific with no DFC analogue?** → Build in V1.

Never build the same resource in both layers. If something lands in V1 because DFC doesn't cover it today, note explicitly whether a future DFC concept could absorb it.

---

## Documentation requirement

Both APIs must have complete, accurate OpenAPI/YAML specs. This is the prerequisite that makes LLM-assisted integration building work — the spec is the interface the LLM works from, not the source code.

- **DFC:** `swagger/dfc.yaml` — generated from the DFC engine's request specs
- **V1:** `swagger/v1.yaml` — regenerate with `bundle exec rake rswag:specs:swaggerize` after each change

A spec that is incomplete or out of date with the implementation undermines the entire integration workflow. Keeping specs current is not documentation work — it is functional work.
