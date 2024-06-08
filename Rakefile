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

file "handlebars.tab.rb" => "handlebars.y" do
  sh "racc handlebars.y"
end

task generate: ["lib/handlebars_lexer.rb", "handlebars.tab.rb"]

task test: :generate

task default: :test
