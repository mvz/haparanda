# frozen_string_literal: true

require "minitest/autorun"
require "minitest/focus"

require "handlebars_lexer"
require "handlebars_parser"
require "handlebars_processor"

require_relative "support/compatibility_test_helpers"
require_relative "support/printing_processor"

# Filter out test support code when showing failure location
Minitest.backtrace_filter =
  Minitest::BacktraceFilter.new(%r{lib/minitest|internal:warning|test/support})
