# frozen_string_literal: true

# Tool to copy and transform original JavaScript spec files to Ruby.

require "pathname"

# Transform one original javascript spec file to ruby-ish target
class FileTransformer
  def initialize(spec_file, target_base, source_name)
    @spec_file = spec_file
    @target_base = target_base
    @source_name = source_name
  end

  attr_reader :spec_file, :target_base, :source_name

  def process
    transform_file
  end

  private

  def base = spec_file.basename

  def target
    target_base.join base.sub("-", "_").sub(".js", "_test.rb")
  end

  def transform_file
    target.open("w") do |fd|
      fd.puts <<~PREAMBLE
        # frozen_string_literal: true

        require "test_helper"

        # Based on spec/#{base} in #{source_name}. The content of the specs should
        # mostly be identical to the content there, so a side-by-side diff should show
        # spec equivalence, and show any new specs that should be added.

      PREAMBLE

      process_lines(fd)
    end
  end

  def process_lines(target_fd)
    spec_file.each_line do |line|
      target_fd.puts process_line(line)
    end
  end

  MATCHERS = [
    [/^( *)\}\);/,
     ->(md) { "#{md[1]}end" }],
    [/^( *)it\((['"].*['"]), function \(\) \{$/,
     lambda { |md|
       ["#{md[1]}it #{md[2]} do",
        "#{md[1]}  skip"]
     }],
    [/^( *)describe\((['"].*['"]), function \(\) \{$/,
     ->(md) { "#{md[1]}describe #{md[2]} do" }],
    [/^(.*) function \(\) \{$/,
     ->(md) { "#{md[1]} lambda {" }],
    [/^(.*) function \((.+)\) \{$/,
     ->(md) { "#{md[1]} lambda { |#{md[2]}|" }],
    [/^( *)var (.*)$/,
     ->(md) { "#{md[1]}#{md[2]}" }]
  ].freeze

  def process_line(line)
    MATCHERS.each do |rx, action|
      if (md = line.match(rx))
        return action.call(md)
      end
    end
    line
  end
end

MAIN_SKIPS = ["ast.js", "compiler.js", "javascript-compiler.js", "precompiler.js",
              "require.js", "runtime.js", "source-map.js", "spec.js", "utils.js"].freeze

PARSER_SKIPS = ["ast.js", "utils.js", "visitor.js"].freeze

base = Pathname.new ARGV[0]
main_js_repo = base.join "handlebars.js/"
js_parser_repo = base.join "handlebars-parser/"
target_base = Pathname.new "./tmp"
target_base.mkpath

specs = main_js_repo.glob "spec/*.js"
specs.each do |spec_file|
  base = spec_file.basename
  next if MAIN_SKIPS.include? base.to_s

  FileTransformer.new(spec_file, target_base, main_js_repo.basename).process
end

specs = js_parser_repo.glob "spec/*.js"
specs.each do |spec_file|
  base = spec_file.basename
  next if PARSER_SKIPS.include? base.to_s

  FileTransformer.new(spec_file, target_base, js_parser_repo.basename).process
end
