# DfcProvider

This engine is implementing the Data Food Consortium specifications in order to serve semantic data.
You can find more details about this on https://github.com/datafoodconsortium.

Basically, it allows an OFN user:
* to retrieve an Access token from DFC Authorization server (using OIDC implemntation)
* to serve his Products Catalog through a dedicated API using JSON-LD format, structured by the DFC Ontology.
