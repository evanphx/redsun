require 'test/unit'
require 'redsun/db'

class TestRedSunDB < Test::Unit::TestCase
  def setup
    @db =  RedSun::DB.new "tmp.db"
    @db2 = RedSun::DB.new "tmp.db"
  end

  def teardown
    File.unlink "tmp.db"
  end

  def test_get_not_there
    val = @db.get "fred", :street
    assert_nil val
  end

  def test_set_and_get
    @db.set_attribute "fred", :street, "Spring St."
    val = @db.get "fred", :street

    assert_equal "Spring St.", val
  end

  def test_get_transaction
    @db.set_attribute "fred", :street, "Spring St."
    t = @db.get_transaction "fred", :street

    assert_equal 1, t
  end

  def test_get_transaction_not_there
    val = @db.get_transaction "fred", :street
    assert_nil val
  end

  def test_set_visible_in_store
    @db.set_attribute "fred", :street, "Spring St."

    val = @db2.get "fred", :street

    assert_equal "Spring St.", val
  end

  def test_get_model
    @db.set_attribute "fred", :name, "Fred"
    @db.set_attribute "fred", :street, "Spring St."

    mod = @db2.get_model "fred"

    assert_equal "Fred", mod[:name]
    assert_equal "Spring St.", mod[:street]
  end

  def test_get_latest_model
    @db.set_attribute "fred", :name, "Fred"
    @db.set_attribute "fred", :street, "Spring St."
    @db.set_attribute "fred", :street, "Maple St."

    mod = @db2.get_model "fred"

    assert_equal "Fred", mod[:name]
    assert_equal "Maple St.", mod[:street]
  end

  def test_get_model_at
    @db.set_attribute "fred", :name, "Fred"
    @db.set_attribute "fred", :street, "Spring St."
    @db.set_attribute "fred", :street, "Maple St."

    mod = @db2.get_model_at "fred", 2

    assert_equal "Fred", mod[:name]
    assert_equal "Spring St.", mod[:street]
  end

  def test_set_model
    mod = { :name => "Fred", :street => "Spring St." }

    t = @db.set_model "fred", mod

    assert_equal t, @db.get_transaction("fred", :name)
    assert_equal t, @db.get_transaction("fred", :street)

    assert_equal mod, @db.get_model("fred")
  end

  def test_get_cached_model
    mod = { :name => "Fred", :street => "Spring St." }

    @db.set_model "fred", mod

    res = @db.get_cached_model "fred"

    assert_equal mod, res
  end

  def test_get_cached_model_invalidated
    mod = { :name => "Fred", :street => "Spring St." }

    @db.set_model "fred", mod

    res = @db.get_cached_model "fred"

    assert_equal mod, res

    mod2 = { :name => "Fred", :street => "Maple St." }
    @db2.set_model "fred", mod2

    assert_nil @db.get_cached_model("fred")
  end

  def test_get_cached_model_invalidated_by_set_attribute
    mod = { :name => "Fred", :street => "Spring St." }

    @db.set_model "fred", mod

    res = @db.get_cached_model "fred"

    assert_equal mod, res

    mod2 = { :name => "Fred", :street => "Maple St." }
    @db2.set_attribute "fred", :street, "Main St."

    assert_nil @db.get_cached_model("fred")
  end
end
