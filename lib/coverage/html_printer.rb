require 'coverage'
require 'coverage/statistics'
require 'fileutils'
require 'erb'
require 'forwardable'

module Coverage
  class HTMLPrinter

    module Utility
      def stylesheet(name, html_filename)
        css = output_directory + "#{name}.css"
        path = css.relative_path_from(Pathname(html_filename).dirname)
        %Q!<link rel="stylesheet" type="text/css" href="#{path.to_s}"/>!
      end

      def javascript(name, html_filename)
        js = output_directory + "#{name}.js"
        path = js.relative_path_from(Pathname(html_filename).dirname)
        %Q!<script src="#{path.to_s}"></script>!
      end

      def coverage_bar(coverage)
        %Q!<div class="bar-container"><div style="width: #{coverage}%"></div></div>#{coverage}%!
      end
    end

    class PathSettings

      attr_reader :output_directory

      def initialize(output_directory)
        @output_directory = output_directory
      end

      def base_directory
        @base_directory ||= Pathname.pwd
      end

      def lib_base_directory
        @lib_base_directory ||= Pathname(__FILE__).dirname.parent.parent
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
    end

    extend Forwardable

    attr_accessor :output_directory, :project_name
    def_delegators(:@path_settings, :base_directory, :lib_base_directory, :output_directory,
                   :templates_directory, :javascripts_directory, :stylesheets_directory)

    def initialize
      yield self if block_given?
      output_directory ||=  Pathname.pwd + "coverage"
      @path_settings = PathSettings.new(output_directory)
      FileUtils.mkdir_p(output_directory)
      @project_name ||= base_directory.basename
    end

    def print(result)
      target_files = Dir.glob("#{base_directory}/**/*.rb")
      statistics_list = []
      files = []
      result.each do |path, counts|
        next unless target_files.include?(path)
        next if Regexp.new("#{base_directory}/(?:test|spec)") =~ path
        files << Detail.new(@path_settings, @project_name, path, counts)
      end
      files.each(&:print_file)
      index = Index.new(@path_settings, @project_name, files)
      index.print_file
      install_files
    end

    def print_index(files)
      erb = ERB.new(File.read(templates_directory + "index.html.erb"), nil, '-')
      erb.filename = "index.html"
      index_path = @path_settings.output_directory + "index.html"
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

    class Index
      include Utility

      attr_reader :project_name, :files

      def initialize(path_settings, project_name, files)
        @path_settings = path_settings
        @project_name = project_name
        @files = files
      end

      def print_file
        erb = ERB.new(File.read(template_path), nil, '-')
        index_path = @path_settings.output_directory + "index.html"
        erb.filename = index_path.to_s
        File.open(index_path, "wb+") do |html|
          html.puts(erb.result(binding))
        end
      end

      def total
        @total ||= @files.inject(0){|memo, detail| memo + detail.total }
      end

      def lines_of_code
        @lines_of_code ||= @files.inject(0){|memo, detail| memo + detail.lines_of_code }
      end

      def total_coverage
        coverage_bar(0)
      end

      def code_coverage
        coverage_bar(0)
      end

      private
      def template_path
        @path_settings.templates_directory + "index.html.erb"
      end

      def output_directory
        @path_settings.output_directory
      end
    end

    class Detail
      extend Forwardable
      include Utility

      def_delegators(:@statistics, :total, :lines_of_code)
      attr_reader :project_name, :page_title

      def initialize(path_settings, project_name, path, counts)
        @path_settings = path_settings
        @project_name = project_name
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

      def print_file
        erb = ERB.new(File.read(template_path), nil, '-')
        path = @path_settings.output_directory + html_filename
        erb.filename = path.to_s
        FileUtils.mkdir_p(path.dirname)
        File.open(path, "wb+") do |file|
          file.puts(erb.result(binding))
        end
      end

      def each_line
        @sources.each do |line|
          yield line
        end
      end

      def label
        @source.relative_path_from(@path_settings.output_directory).to_s.sub(/\A\.\.\//, '')
      end

      def html_filename
        dir = @source.sub(Regexp.new(@path_settings.base_directory.to_s), '.').dirname
        file = @source.basename.sub(/\.rb/, "_rb.html")
        dir + file
      end

      def total_coverage
        coverage_bar(@statistics.total_coverage)
      end

      def code_coverage
        coverage_bar(@statistics.code_coverage)
      end

      def print
      end

      private
      def template_path
        @path_settings.templates_directory + "detail.html.erb"
      end

      def output_directory
        @path_settings.output_directory
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

