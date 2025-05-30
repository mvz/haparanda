# frozen_string_literal: true

require_relative "lib/haparanda/version"

Gem::Specification.new do |spec|
  spec.name = "haparanda"
  spec.version = Haparanda::VERSION
  spec.authors = ["Matijs van Zuijlen"]
  spec.email = ["matijs@matijs.net"]

  spec.summary = "Pure Ruby Handlebars Parser"
  spec.description = <<~DESC
    Haparanda aims to be a fast implementation of all of Handlebars written in
    Ruby. The lexer and parser track the upstream .l and .y files.
  DESC
  spec.homepage = "https://github.com/mvz/haparanda"

  spec.license = "LGPL-2.1-or-later"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mvz/haparanda"
  spec.metadata["changelog_uri"] = "https://github.com/mvz/haparanda/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = File.read("Manifest.txt").split
  spec.require_paths = ["lib"]

  spec.rdoc_options = ["--main", "README.md"]
  spec.extra_rdoc_files = ["README.md", "CHANGELOG.md"]

  spec.add_dependency "racc", "~> 1.8"
  spec.add_dependency "sexp_processor", "~> 4.17"
end
