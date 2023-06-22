# Data Food Consortium API for the Open Food Network app (OFN DFC API)

This engine implements the [Data Food Consortium] specifications. It serves and
reads semantic data encoded in JSON-LD.

[Data Food Consortium]: https://github.com/datafoodconsortium

## Authentication

The DFC uses OpenID Connect (OIDC) to authenticate requests. You need an
account with a trusted OIDC provider. Currently these are:

* https://login.lescommuns.org/auth/

But you can also authenticate with your OFN user login (session cookie) through
your browser.

And you can also use your OFN API token in the HTTP header. For example:

```
X-Api-Token: d6ccf8685b8cd29b67ae6186e9ceb423bd2ac30b7c880223
```

## API endpoints

The API is under development and this list may be out of date.

```
/api/dfc-v1.7/persons/:id
 * show: firstName, lastName, affiliatedOrganizations

/api/dfc-v1.7/enterprises/:id
 * show: name, suppliedProducts, catalogItems

/api/dfc-v1.7/enterprises/:enterprise_id/supplied_products (index)

/api/dfc-v1.7/enterprises/:enterprise_id/supplied_products/:id
 * create: name, description, quantity
 * show: name, description, productType, quantity
 * update: description

/api/dfc-v1.7/enterprises/:enterprise_id/catalog_items (index)

/api/dfc-v1.7/enterprises/:enterprise_id/catalog_items/:id
 * show: product, sku, stockLimitation, offers (price, stockLimitation)
 * update: sku, stockLimitation
```
