require 'coverage'
require 'coverage/statistics'
require 'fileutils'
require 'erb'

module Coverage
  class HTMLPrinter

    attr_accessor :output_directory, :project_name
    attr_reader :base_directory

    def initialize
      @base_directory = Pathname(__FILE__).dirname.parent.parent
      @output_directory = Pathname.pwd + "coverage"
      FileUtils.mkdir_p(@output_directory)
      @project_name ||= "test"
    end

    def print(result)
      result.each do |path, counts|
        next if /test-unit/ =~ path
        source = Pathname(path)
        page_title = source.basename
        sources = []
        source.each_line.with_index.zip(counts) do |(line, index), count|
          sources << Line.new(index + 1, line, count)
        end
        statistics = Coverage::Statistics.new(path, counts)
        erb = ERB.new(File.read(templates_directory + "detail.html.erb"), nil, '-')
        File.open(@output_directory + html_filename(source), "wb+") do |html|
          html.puts(erb.result(binding))
        end
      end
    end

    def html_filename(path)
      path.basename.sub(/\.rb/, "_rb.html")
    end

    def templates_directory
       base_directory + "data/templates"
    end

    def javascripts_directory
      base_directory + "data/javascripts"
    end

    def stylesheets_directory
      base_directory + "data/stylesheets"
    end

    class Line

      attr_accessor :lineno, :count

      def initialize(lineno, line, count)
        @lineno = lineno
        @line   = line
        @count  = count
      end

      def line
        return "&#x200c;\n" if @line.chomp.size == 0
        @line
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

