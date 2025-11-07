# frozen_string_literal: true

SimpleCov.start do
  add_group "Library" do |file|
    filename = file.project_filename
    filename.start_with?("/lib/") &&
      !["/lib/haparanda/handlebars_lexer.rb",
        "/lib/haparanda/handlebars_parser.rb"].include?(filename)
  end
  add_group "Generated Code",
            ["lib/haparanda/handlebars_lexer.rb", "lib/haparanda/handlebars_parser.rb"]
  add_group "Tests",
            ["test/test_helper.rb", "test/support", "test/haparanda", "test/integration"]
  add_group "Compatibility Tests", "test/compatibility"
  add_group "Mustache Tests", "test/mustache"
  enable_coverage :branch
end
