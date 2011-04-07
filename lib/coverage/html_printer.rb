require 'coverage'
require 'coverage/statistics'
require 'erb'

module Coverage
  class HTMLPrinter
    def initialize
    end

    def print(result)
      result.each do |path, counts|
        next if /test-unit/ =~ path
        source = Pathname(path)
        source.each_line.with_index.zip(counts) do |(line, index), count|
          
        end
      end
    end
  end
end

