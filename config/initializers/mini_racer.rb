# frozen_string_literal: true

# We need to configure MiniRacer to allow forking.
# We do that for background jobs like reports.
# https://github.com/rubyjs/mini_racer#fork-safety
MiniRacer::Platform.set_flags!(:single_threaded)
