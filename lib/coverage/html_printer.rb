require 'coverage'
require 'coverage/statistics'
require 'fileutils'
require 'erb'

module Coverage
  class HTMLPrinter

    attr_accessor :output_directory, :project_name
    attr_reader :lib_base_directory, :base_directory

    def initialize
      yield self if block_given?
      @lib_base_directory = Pathname(__FILE__).dirname.parent.parent
      @base_directory = Pathname.pwd
      @output_directory ||=  @base_directory + "coverage"
      FileUtils.mkdir_p(@output_directory)
      @project_name ||= "test"
    end

    def print(result)
      target_files = Dir.glob("#{@base_directory}/**/*.rb")
      result.each do |path, counts|
        next unless target_files.include?(path)
        next if Regexp.new("#{@base_directory}/(?:test|spec)") =~ path
        source = Pathname(path)
        page_title = source.basename
        sources = []
        source.each_line.with_index.zip(counts) do |(line, index), count|
          sources << Line.new(index + 1, line, count)
        end
        statistics = Coverage::Statistics.new(path, counts)
        erb = ERB.new(File.read(templates_directory + "detail.html.erb"), nil, '-')
        html_filepath = @output_directory + html_filename(source)
        FileUtils.mkdir_p(html_filepath.dirname)
        File.open(html_filepath, "wb+") do |html|
          html.puts(erb.result(binding))
        end
      end
      install_files
    end

    def install_files
      [javascripts_directory, stylesheets_directory].zip(%w[js css]) do |dir, ext|
        FileUtils.install(dir + "coverage.#{ext}", output_directory)
      end
    end

    def html_filename(path)
      dir = path.sub(Regexp.new(base_directory.to_s), '.').dirname
      file = path.basename.sub(/\.rb/, "_rb.html")
      dir + file
    end

    def templates_directory
       lib_base_directory + "data/templates"
    end

    def javascripts_directory
      lib_base_directory + "data/javascripts"
    end

    def stylesheets_directory
      lib_base_directory + "data/stylesheets"
    end

    class Line
      include ERB::Util

      attr_accessor :lineno, :count

      def initialize(lineno, line, count)
        @lineno = lineno
        @line   = line
        @count  = count
      end

      def line
        return "&#x200c;\n" if @line.chomp.size == 0
        h(@line).gsub(/ /, '&nbsp;')
      end

      def class_name
        case
        when @count.nil?
          'not-code'
        when @count > 0
          'executed'
        when @count == 0
          'unexecuted'
        else
          raise "must not happen! count=<#{@count}>"
        end
      end

      def color_name
        case
        when @count.nil?
          'grey'
        when @count > 0
          'green'
        when @count == 0
          'pink'
        else
          raise "must not happen! count=<#{@count}>"
        end
      end
    end
  end
end

