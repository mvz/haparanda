# frozen_string_literal: true

require "minitest/autorun"
require "minitest/focus"
require "handlebars_lexer"
require "handlebars_parser"

require_relative "support/printing_processor"
require_relative "support/ast_testing"
require_relative "support/template_tester"

# Filter out test support code when showing failure location
Minitest.backtrace_filter =
  Minitest::BacktraceFilter.new(/lib\/minitest|internal:warning|test\/support/)
