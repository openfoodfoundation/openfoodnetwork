Rails.application.reloader.to_prepare do
  # Ignore noisy StateMachines warnings.
  StateMachines::Machine.ignore_method_conflicts = true
end
