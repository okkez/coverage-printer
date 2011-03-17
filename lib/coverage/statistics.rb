module Coverage
  class Statistics

    attr_reader :path, :counts

    def initialize(path, counts)
      @path = path
      @counts = counts
    end

    def total
      counts.size
    end

    def lines_of_code
      counts.compact.size
    end

    def total_coverage
      (executed_lines / tolat_covrage.to_f) * 100
    end

    def code_coverage
      (executed_lines / lines_of_code) * 100
    end

    # FIXME more suitable method name
    def executed_lines
      counts.select{|count| count > 0 }.size
    end
  end
end
