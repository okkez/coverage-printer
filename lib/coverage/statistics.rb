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
      "%.2f" % [(lines_of_covered_code / total.to_f) * 100]
    end

    def code_coverage
      "%.2f" % [(lines_of_covered_code / lines_of_code.to_f) * 100]
    end

    def lines_of_covered_code
      counts.select{|count| count && count > 0 }.size
    end
  end
end
