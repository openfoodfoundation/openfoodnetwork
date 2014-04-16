Darkswarm.factory 'CheckoutFormState', ()->
  # This class only exists to encapsulate a single field: checkout_state_same_as_billing
  # So we can cleanly access it from the Order service as well as the scope
  new class CheckoutFormState
