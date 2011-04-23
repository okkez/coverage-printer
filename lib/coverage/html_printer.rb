require 'coverage'
require 'coverage/statistics'
require 'fileutils'
require 'erb'
require 'forwardable'

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
      statistics_list = []
      files = []
      result.each do |path, counts|
        next unless target_files.include?(path)
        next if Regexp.new("#{@base_directory}/(?:test|spec)") =~ path
        files << Source.new(@base_directory, path, counts)
      end
      files.each do |file|
        print_detail(file)
      end
      print_index(files)
      install_files
    end

    def print_detail(file)
      erb = ERB.new(File.read(templates_directory + "detail.html.erb"), nil, '-')
      html_filepath = @output_directory + file.html_filename
      erb.filename = html_filepath.to_s
      FileUtils.mkdir_p(html_filepath.dirname)
      File.open(html_filepath, "wb+") do |html|
        html.puts(erb.result(binding))
      end
    end

    def print_index(files)
      erb = ERB.new(File.read(templates_directory + "index.html.erb"), nil, '-')
      erb.filename = "index.html"
      index_path = @output_directory + "index.html"
      File.open(index_path, "wb+") do |html|
        html.puts(erb.result(binding))
      end
    end

    def install_files
      stylesheets_directory.each_child do |path|
        FileUtils.install(path, output_directory)
      end
      javascripts_directory.each_child do |path|
        FileUtils.install(path, output_directory)
      end
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

    def stylesheet(name, html_filename)
      css = @output_directory + "#{name}.css"
      path = css.relative_path_from(Pathname(html_filename).dirname)
      %Q!<link rel="stylesheet" type="text/css" href="#{path.to_s}"/>!
    end

    def javascript(name, html_filename)
      js = @output_directory + "#{name}.js"
      path = js.relative_path_from(Pathname(html_filename).dirname)
      %Q!<script src="#{path.to_s}"></script>!
    end

    class Source
      extend Forwardable

      def_delegators(:@statistics, :total, :lines_of_code)
      attr_reader :page_title

      def initialize(base_directory, path, counts)
        @base_directory = base_directory
        @path = path
        @counts = counts
        @statistics = Coverage::Statistics.new(path, counts)
        @source = Pathname(path)
        @page_title = @source.basename
        @sources = []
        @source.each_line.with_index.zip(@counts) do |(line, index), count|
          @sources << Line.new(index + 1, line, count)
        end
      end

      def each_line
        @sources.each do |line|
          yield line
        end
      end

      # TODO return relative path
      def label
        @path
      end

      def html_filename
        dir = @source.sub(Regexp.new(@base_directory.to_s), '.').dirname
        file = @source.basename.sub(/\.rb/, "_rb.html")
        dir + file
      end

      def total_coverage
        coverage_bar(@statistics.total_coverage)
      end

      def code_coverage
        coverage_bar(@statistics.code_coverage)
      end

      private
      def coverage_bar(coverage)
        %Q!<div class="bar-container"><div style="width: #{coverage}%"></div></div>#{coverage}%!
      end
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
          'covered'
        when @count == 0
          'uncovered'
        else
          raise "must not happen! count=<#{@count}>"
        end
      end
    end
  end
end

