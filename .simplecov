# frozen_string_literal: true

SimpleCov.configure do
  # Remove the "test_frameworks" filter
  clear_filters
  load_profile "bundler_filter"
  load_profile "hidden_filter"
  load_profile "root_filter"

  group "Library" do |file|
    filename = file.project_filename
    filename.start_with?("lib/") &&
      !["lib/haparanda/handlebars_lexer.rb",
        "lib/haparanda/handlebars_parser.rb"].include?(filename)
  end
  group "Generated Code",
        ["lib/haparanda/handlebars_lexer.rb", "lib/haparanda/handlebars_parser.rb"]
  group "Tests",
        ["test/test_helper.rb", "test/support", "test/haparanda", "test/integration"]
  group "Compatibility Tests", "test/compatibility"
  group "Mustache Tests", "test/mustache"
  enable_coverage :branch
end
