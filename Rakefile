# frozen_string_literal: true

file "handlebars.l.rb" => "handlebars.l" do
  sh "rex handlebars.l --stub"
end

file "handlebars.tab.rb" => "handlebars.y" do
  sh "racc handlebars.y"
end

task default: ["handlebars.l.rb", "handlebars.tab.rb"]
