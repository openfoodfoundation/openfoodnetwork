# https://github.com/zombocom/rack-timeout/blob/main/doc/logging.md
# state changes into timed_out and expired are logged at the ERROR level

# Log ready and completed messages in DEBUG mode only (instead of default INFO)
Rack::Timeout::StateChangeLoggingObserver::STATE_LOG_LEVEL[:ready] = :debug
Rack::Timeout::StateChangeLoggingObserver::STATE_LOG_LEVEL[:completed] = :debug

