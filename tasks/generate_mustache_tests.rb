# frozen_string_literal: true

require "yaml"

desc "Generate mustache compatibility tests"
task :generate_mustache_tests do
  base_dir = File.join __dir__, ".."
  test_dir = File.join base_dir, "test/mustache"
  FileUtils.mkdir_p test_dir

  spec_files = Dir.glob File.join base_dir, "ext/mustache-spec/specs/[^~]*.yml"

  spec_files.each do |file|
    base = File.basename file, ".yml"
    specs = YAML.load_file file

    spec_file_name = File.join test_dir, "#{base}_test.rb"

    File.open spec_file_name, "w" do |spec_file|
      spec_file << "# frozen_string_literal: true\n\n"

      spec_file << "require \"test_helper\"\n\n"
      spec_file << "describe \"#{base}\" do\n"

      spec_file << "  let(:compiler) { Haparanda::Compiler.new }\n"

      specs["tests"].each do |spec|
        name = spec["name"]
        desc = spec["desc"]
        data = spec["data"]
        template = spec["template"]
        expected = spec["expected"]
        partials = spec["partials"] || {}

        spec_file << "  describe \"#{name}\" do\n"
        spec_file << "    specify #{desc.inspect} do\n"

        if base == "partials" && spec["name"] == "Failed Lookup"
          spec_file << "      skip \"Handlebars raises error if partial is not found\"\n"
        end
        if base == "partials" && spec["name"] == "Standalone Indentation"
          spec_file << "      skip \"Handlebars nests the entire response from partials, " \
                       "not just the literals\"\n"
        end
        if /\{\{=/.match? template
          spec_file << "      skip \"Handlebars does not support alternative delimiters\"\n"
        end
        if partials.values.any? { |partial| /\{\{=/.match? partial }
          spec_file << "      skip \"Handlebars does not support alternative delimiters\"\n"
        end

        partials.each do |name, partial|
          spec_file << "      compiler.register_partial(\"#{name}\", #{partial.inspect})\n"
        end

        spec_file << "      template = #{template.inspect}\n"
        spec_file << "      input = #{data.inspect}\n"
        spec_file << "      result = compiler.compile(template, compat: true).call(input)\n"
        spec_file << "      _(result).must_equal #{expected.inspect}\n"
        spec_file << "    end\n"
        spec_file << "  end\n"
      end

      spec_file << "end\n"
    end
  end
end
