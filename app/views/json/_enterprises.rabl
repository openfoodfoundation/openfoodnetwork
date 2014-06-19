# TODO: This should be moved into the controller
# RABL is tricky to pass variables into: so we do this as a workaround for now
# I noticed some vague comments on Rabl github about this, but haven't looked into
collection Enterprise.visible 
extends 'json/partials/enterprise'
extends 'json/partials/producer'
extends 'json/partials/hub'
