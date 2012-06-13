require 'test/unit'
require 'redsun/query_engine'

class TestRedSunQueryEngine < Test::Unit::TestCase
  def assert_empty(r)
    assert r.empty?, "Array was not empty"
  end

  def setup
    @q = RedSun::QueryEngine.new
    @d = [[1, "name", "Fred"], [2, "name", "Wilma"]]
    @d2 = @d + [3, "age", 42]
  end

  def test_find_all_when_empty
    r = @q.find [:a, :b, :c], [:a]
    assert_empty r
  end

  def test_find_all
    @q.load @d

    r = @q.find [:a, :b, :c], [:a]

    assert_equal [[1], [2]], r
  end

  def test_find_matching
    @q.load @d

    r = @q.find [:a, :b, "Fred"], [:a]

    assert_equal [[1]], r
  end

  def test_find_with_muliple_constraints
    @q.load @d2

    r = @q.find [:e, "name", :v], [:e, :v]

    assert_equal [[1, "Fred"], [2, "Wilma"]], r
  end

  def test_find_with_mulitple_matches
    @q.load @d

    r = @q.find [[:e, "name", :v], [:e, :a, "Fred"]], [:e]

    assert_equal [[1]], r
  end

  def test_find_and_select_from_different_records
    d3 = [
      [1, "person.name", "Fred"],
      [2, "person.name", "Wilma"],
      [3, "company.name", "Rock Quarry"],
      [4, "company.name", "Astrophysics Corp"],
      [1, "person.company", 3],
      [2, "person.company", 4]]

    @q.load d3

    r = @q.find [[:e, "person.name", :v],
                 [:e, "person.company", :c],
                 [:c, "company.name", :v2]],
                [:v, :v2]

    assert_equal [["Fred", "Rock Quarry"], ["Wilma", "Astrophysics Corp"]], r
  end
end
