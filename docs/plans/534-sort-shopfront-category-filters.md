# Issue #534: Sort product category filters on shopfront

**Issue:** https://github.com/openfoodfoundation/wishlist/issues/534
**Label:** good first issue
**Affects:** Shoppers, Hub Managers, Producers

---

## Problem

The product category filter buttons on the shopfront sidebar appear in an arbitrary order — neither alphabetical nor consistent with the "display ordering in shopfront" setting in Shop Preferences. Enterprises receive shopper complaints about navigation difficulty when there are many products across many categories.

**Two scenarios to fix:**
1. **Default**: display category filter buttons alphabetically.
2. **Configured**: if the enterprise has set a "Sort by category" order in Shop Preferences, use that same order for the filter buttons.

---

## Current System — How It Works

### Shop Preferences (Admin)

Enterprise has three shopfront sorting preferences stored in `spree_preferences`:

| Preference | Default | Purpose |
|---|---|---|
| `preferred_shopfront_product_sorting_method` | `"by_category"` | Which sort method: `"by_category"`, `"by_producer"`, or default alpha |
| `preferred_shopfront_taxon_order` | `""` | Comma-separated taxon IDs in preferred display order, e.g. `"3,1,2"` |
| `preferred_shopfront_producer_order` | `""` | Comma-separated producer IDs (not relevant here) |

Set in admin UI at `app/views/admin/enterprises/form/_shop_preferences.html.haml`.

### Product Ordering (Works Correctly)

`app/services/order_cycles/distributed_products_service.rb` correctly uses `preferred_shopfront_taxon_order` to build SQL `ORDER BY` clauses sorting *products* by category. This is working as intended.

### Category Filter Buttons (Broken)

**Step 1 — API endpoint (`app/controllers/api/v0/order_cycles_controller.rb:35`):**

```ruby
def taxons
  taxons = Spree::Taxon.
    joins(:products).
    where(spree_products: { id: distributed_products }).
    select('DISTINCT spree_taxons.*')   # ← NO ORDER BY

  render plain: ActiveModel::ArraySerializer.new(
    taxons, each_serializer: Api::TaxonSerializer
  ).to_json
end
```

No `ORDER BY` means PostgreSQL returns taxons in an arbitrary order (typically heap scan order, which varies).

**Step 2 — Frontend stores taxons as a JS object (`app/assets/javascripts/darkswarm/controllers/products_controller.js.coffee:39`):**

```coffeescript
OrderCycleResource.taxons params, (data)=>
  $scope.supplied_taxons = {}
  data.map( (taxon) ->
    $scope.supplied_taxons[taxon.id] = Taxons.taxons_by_id[taxon.id]
  )
```

`supplied_taxons` is a plain JavaScript object with integer taxon IDs as keys. Per the ECMAScript spec, JavaScript engines iterate integer-indexed object properties in **ascending numeric order**, regardless of insertion order. So even if the API returned taxons in alphabetical or preferred order, this step destroys that ordering.

**Step 3 — Directive iterates the object in ID order (`app/assets/javascripts/darkswarm/directives/filter_selector.js.coffee:35`):**

```coffeescript
for id, object of scope.objects()
  # iterates by ascending taxon ID — e.g. id 1, 2, 3...
```

The result: filter buttons always appear in ascending database-ID order, which is arbitrary from the user's perspective.

---

## Root Cause Summary

There are **two independent bugs**, both of which must be fixed:

1. **Backend**: the `/api/v0/order_cycles/:id/taxons.json` endpoint has no `ORDER BY`.
2. **Frontend**: `supplied_taxons` is stored as a plain JS object with integer keys, causing JavaScript to re-order by ascending ID regardless of what the API returns.

Fixing only the backend would have no visible effect. Fixing only the frontend (sort alphabetically in the directive) resolves Scenario 1 but cannot support Scenario 2 (preferred order) without also getting that order information to the frontend.

---

## Proposed Solution

### Part 1 — Backend: Sort taxons in the API response

**File:** `app/controllers/api/v0/order_cycles_controller.rb`

Sort taxons alphabetically by default. If the distributor has `by_category` sorting configured with a taxon order, sort by that order instead (using Ruby sort, since the number of categories is small).

```ruby
def taxons
  taxons = Spree::Taxon.
    joins(:products).
    where(spree_products: { id: distributed_products }).
    select('DISTINCT spree_taxons.*')

  taxons = sort_taxons(taxons)

  render plain: ActiveModel::ArraySerializer.new(
    taxons, each_serializer: Api::TaxonSerializer
  ).to_json
end

# in private section:
def sort_taxons(taxons)
  taxon_order = distributor&.preferred_shopfront_taxon_order

  if distributor&.preferred_shopfront_product_sorting_method == "by_category" &&
     taxon_order.present?
    ordered_ids = taxon_order.split(',').map(&:to_i)
    taxons.sort_by do |taxon|
      idx = ordered_ids.index(taxon.id)
      [idx || ordered_ids.length, taxon.name]  # unrecognised taxons go to end, then alpha
    end
  else
    taxons.sort_by(&:name)
  end
end
```

Note: the `caches_action` cache key is the full request URL, which includes the `distributor` param, so different distributors get different cached responses. Cache TTL is 30 seconds (`CacheService::FILTERS_EXPIRY`), so preference changes take effect within 30 seconds. (The `#products` action is not action-cached, so there is no equivalent staleness concern there.)

### Part 2 — Frontend: Preserve the sort order from the API

The JS object structure must be changed so that insertion order is preserved. Change `supplied_taxons` from a hash to an **array** of taxon objects. The API returns them in the correct order; we just need to stop JavaScript from re-ordering them.

**File:** `app/assets/javascripts/darkswarm/controllers/products_controller.js.coffee`

```coffeescript
# Before:
$scope.supplied_taxons = {}
data.map( (taxon) ->
  $scope.supplied_taxons[taxon.id] = Taxons.taxons_by_id[taxon.id]
)

# After:
$scope.supplied_taxons = data.map( (taxon) ->
  Taxons.taxons_by_id[taxon.id]
).filter (t) -> t?
```

**File:** `app/assets/javascripts/darkswarm/directives/filter_selector.js.coffee`

Update `buildSelectors` to handle an array input in addition to the existing hash input (properties/producer_properties are still hashes):

```coffeescript
scope.buildSelectors = ->
  selectors = []
  objects = scope.objects()
  items = if angular.isArray(objects)
    objects
  else
    (v for k, v of objects)
  for object in items
    id = object.id
    if selector = selectors_by_id[id]
      selectors.push selector
    else
      selector = selectors_by_id[id] = scope.selectorSet.new
        object: object
      selectors.push selector
  selectors
```

The `for id, object of` idiom (hash iteration) and `for object in` idiom (array iteration) are handled by the type check. Properties and producer_properties continue working unchanged since they remain hashes.

---

## Files to Change

| File | Change |
|---|---|
| `app/controllers/api/v0/order_cycles_controller.rb` | Add `sort_taxons` method; call it in `taxons` action |
| `app/assets/javascripts/darkswarm/controllers/products_controller.js.coffee` | Change `supplied_taxons` from hash to array |
| `app/assets/javascripts/darkswarm/directives/filter_selector.js.coffee` | Handle array input in `buildSelectors` |
| `spec/controllers/api/v0/order_cycles_controller_spec.rb` | Add ordering assertions to the `#taxons` spec |

---

## Tests to Update / Add

**`spec/controllers/api/v0/order_cycles_controller_spec.rb`**

The existing `#taxons` spec only checks presence (`include`), not order. Add ordering tests inside `describe "#taxons"`.

**Important:** the alphabetical ordering test must use taxon names whose alphabetical order differs from their ID (creation) order, otherwise the test passes on unfixed code. The existing `taxon1 = 'Meat'` and `taxon2 = 'Vegetables'` are already in alphabetical order by ID, so a third taxon (`'Apples'`) created after them — with a higher ID — is needed to prove the fix:

```ruby
describe "#taxons" do
  # existing test kept as-is...

  context "with a taxon whose name sorts before those with lower IDs" do
    let!(:taxon_apple) { create(:taxon, name: 'Apples') }
    let!(:product_apple) { create(:product, primary_taxon: taxon_apple) }

    before { exchange.variants << product_apple.variants.first }

    it "returns taxons in alphabetical order by default" do
      api_get :taxons, id: order_cycle.id, distributor: distributor.id

      expect(json_response.pluck(:name)).to eq ['Apples', 'Meat', 'Vegetables']
    end
  end

  context "when distributor has a preferred taxon order set" do
    before do
      distributor.preferred_shopfront_product_sorting_method = "by_category"
      distributor.preferred_shopfront_taxon_order = "#{taxon2.id},#{taxon1.id}"
      distributor.save!
    end

    it "returns taxons in the preferred order" do
      api_get :taxons, id: order_cycle.id, distributor: distributor.id

      expect(json_response.pluck(:name)).to eq [taxon2.name, taxon1.name]
    end

    it "appends taxons not in the preferred order alphabetically at the end" do
      distributor.preferred_shopfront_taxon_order = "#{taxon2.id},9999999"
      distributor.save!

      api_get :taxons, id: order_cycle.id, distributor: distributor.id

      expect(json_response.pluck(:name).first).to eq taxon2.name
      expect(json_response.pluck(:name)).to include taxon1.name
    end
  end
end
```

JS unit tests exist at `spec/javascripts/unit/darkswarm/controllers/products_controller_spec.js.coffee` but do not cover `update_filters` or `supplied_taxons`, so the hash→array change will not break them. Main coverage for the frontend change comes from `spec/system/consumer/shopping/`.

---

## Scope Boundaries

- **Out of scope**: sorting the properties/producer_properties filter buttons — that's a separate concern.
- **Out of scope**: any changes to the admin "display ordering" UI — it already works for products.
- **No new migrations needed**: all data already lives in `spree_preferences`.
- **No API version bumps needed**: response shape is unchanged (same JSON, just reordered).

---

## Caveats

- The `sort_taxons` Ruby sort materialises the AR relation into an array. With very large numbers of distinct taxons this costs a small amount of memory, but in practice any single OC will have at most a few dozen categories.
- The action cache (`caches_action`) uses the request URL as the key. If a distributor changes their taxon order preference, the old cached response will be served for up to 30 seconds before expiring. The `#products` action is not action-cached, so there is no equivalent stale-ordering window on the products side — but 30 seconds is acceptable for an infrequently-changed preference.
