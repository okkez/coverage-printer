require 'test_helper'
require 'coverage/statistics'

module Coverage
  class StatisticsTest < Test::Unit::TestCase

    def setup
      @statistics = Statistics.new('test.rb',
                                   [nil, 1, 0, 1, nil, 0, 1, 0, nil, nil])
    end

    def test_total
      assert_equal(10, @statistics.total)
    end

    def test_lines_of_code
      assert_equal(6, @statistics.lines_of_code)
    end

    def test_lines_of_executed_code
      assert_equal(3, @statistics.lines_of_executed_code)
    end

    def test_total_coverage
      assert_equal(30, @statistics.total_coverage)
    end

    def test_code_coverage
      assert_equal(50, @statistics.code_coverage)
    end
  end
end
