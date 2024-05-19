# frozen_string_literal: true

file "handlebars.l.rb" => "handlebars.l" do
  sh "rex handlebars.l --stub"
end

task default: "handlebars.l.rb"
