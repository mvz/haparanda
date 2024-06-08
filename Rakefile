# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs = ["lib"]
  t.ruby_opts += ["-w -Itest"]
  t.test_files = FileList["test/**/*_test.rb"]
end

file "lib/handlebars_lexer.rb" => "lib/handlebars_lexer.rex" do
  sh "rex lib/handlebars_lexer.rex --independent -o lib/handlebars_lexer.rb"
end

file "lib/handlebars_parser.rb" => "lib/handlebars_parser.y" do
  sh "racc lib/handlebars_parser.y -F -o lib/handlebars_parser.rb"
end

task generate: ["lib/handlebars_lexer.rb", "lib/handlebars_parser.rb"]

task test: :generate

task default: :test
