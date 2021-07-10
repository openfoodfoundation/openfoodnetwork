# DfcProvider

This engine is implementing the Data Food Consortium specifications in order to serve semantic data.
You can find more details about this on https://github.com/datafoodconsortium.

Basically, it allows an OFN user linked to an enterprise:
* to serve his Products Catalog through a dedicated API using JSON-LD format, structured by the DFC Ontology
* to be authenticated thanks to an Access Token from DFC Authorization server (using an OIDC implementation)

The API endpoint for the catalog is `/api/dfc_provider/enterprise/prodcuts.json` and you need to pass the token inside an authentication header (`Authentication: Bearer 123mytoken456`).

This feature is still under active development.