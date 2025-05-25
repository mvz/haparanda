# frozen_string_literal: true

require "minitest/autorun"
require "minitest/focus"

require "haparanda"

require_relative "support/compatibility_test_helpers"
require_relative "support/printing_processor"

# Filter out test support code when showing failure location
Minitest.backtrace_filter =
  Minitest::BacktraceFilter.new(%r{lib/minitest|internal:warning|test/support})
