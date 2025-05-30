# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "rake/manifest/task"

Minitest::TestTask.create(:test) do |t|
  t.libs << "lib"
  t.libs << "test"
  t.warning = true
  t.test_globs = ["test/**/*_test.rb"]
  t.test_prelude = %(require "simplecov"; SimpleCov.start)
end

Rake::Manifest::Task.new do |t|
  t.patterns = ["{lib}/**/*", "COPYING.LIB"]
end

file "lib/haparanda/handlebars_lexer.rb" => "lib/haparanda/handlebars_lexer.rex" do
  sh "rex lib/haparanda/handlebars_lexer.rex --independent " \
     "-o lib/haparanda/handlebars_lexer.rb"
end

file "lib/haparanda/handlebars_parser.rb" => "lib/haparanda/handlebars_parser.y" do
  sh "racc lib/haparanda/handlebars_parser.y -v -F -o lib/haparanda/handlebars_parser.rb"
end

task generate: ["lib/haparanda/handlebars_lexer.rb", "lib/haparanda/handlebars_parser.rb"]

task test: :generate
task "manifest:generate" => :generate

task default: :test
