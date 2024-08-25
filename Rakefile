# frozen_string_literal: true

require "minitest/test_task"

Minitest::TestTask.create(:test) do |t|
  t.libs << "lib"
  t.libs << "test"
  t.warning = true
  t.test_globs = ["test/**/*_test.rb"]
  t.test_prelude = %(require "simplecov"; SimpleCov.start)
end

file "lib/handlebars_lexer.rb" => "lib/handlebars_lexer.rex" do
  sh "rex lib/handlebars_lexer.rex --independent -o lib/handlebars_lexer.rb"
end

file "lib/handlebars_parser.rb" => "lib/handlebars_parser.y" do
  sh "racc lib/handlebars_parser.y -v -F -o lib/handlebars_parser.rb"
end

task generate: ["lib/handlebars_lexer.rb", "lib/handlebars_parser.rb"]

task test: :generate

task default: :test
