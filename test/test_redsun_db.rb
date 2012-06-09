require 'test/unit'
require 'redsun/db'

class TestRedSunDB < Test::Unit::TestCase
  def setup
    @db =  RedSun::DB.new "tmp.db"
    @db2 = RedSun::DB.new "tmp.db"

    @entity = 1
  end

  def teardown
    File.unlink "tmp.db"
  end

  def test_get_not_there
    val = @db.get @entity, :street
    assert_nil val
  end

  def test_set_and_get
    @db.set_attribute @entity, :street, "Spring St."
    val = @db.get @entity, :street

    assert_equal "Spring St.", val
  end

  def test_get_transaction
    @db.set_attribute @entity, :street, "Spring St."
    t = @db.get_transaction @entity, :street

    assert_equal 1, t
  end

  def test_get_transaction_not_there
    val = @db.get_transaction @entity, :street
    assert_nil val
  end

  def test_set_visible_in_store
    @db.set_attribute @entity, :street, "Spring St."

    val = @db2.get @entity, :street

    assert_equal "Spring St.", val
  end

  def test_get_entity
    @db.set_attribute @entity, :name, "Fred"
    @db.set_attribute @entity, :street, "Spring St."

    mod = @db2.get_entity @entity

    assert_equal "Fred", mod[:name]
    assert_equal "Spring St.", mod[:street]
  end

  def test_get_latest_entity
    @db.set_attribute @entity, :name, "Fred"
    @db.set_attribute @entity, :street, "Spring St."
    @db.set_attribute @entity, :street, "Maple St."

    mod = @db2.get_entity @entity

    assert_equal "Fred", mod[:name]
    assert_equal "Maple St.", mod[:street]
  end

  def test_get_entity_at
    @db.set_attribute @entity, :name, "Fred"
    @db.set_attribute @entity, :street, "Spring St."
    @db.set_attribute @entity, :street, "Maple St."

    mod = @db2.get_entity_at @entity, 2

    assert_equal "Fred", mod[:name]
    assert_equal "Spring St.", mod[:street]
  end

  def test_set_entity
    mod = { :name => "Fred", :street => "Spring St." }

    t = @db.set_entity @entity, mod

    assert_equal t, @db.get_transaction(@entity, :name)
    assert_equal t, @db.get_transaction(@entity, :street)

    assert_equal mod, @db.get_entity(@entity)
  end

  def test_get_cached_entity
    mod = { :name => "Fred", :street => "Spring St." }

    @db.set_entity @entity, mod

    res = @db.get_cached_entity @entity

    assert_equal mod, res
  end

  def test_get_cached_entity_invalidated
    mod = { :name => "Fred", :street => "Spring St." }

    @db.set_entity @entity, mod

    res = @db.get_cached_entity @entity

    assert_equal mod, res

    mod2 = { :name => "Fred", :street => "Maple St." }
    @db2.set_entity @entity, mod2

    assert_nil @db.get_cached_entity(@entity)
  end

  def test_get_cached_entity_invalidated_by_set_attribute
    mod = { :name => "Fred", :street => "Spring St." }

    @db.set_entity @entity, mod

    res = @db.get_cached_entity @entity

    assert_equal mod, res

    mod2 = { :name => "Fred", :street => "Maple St." }
    @db2.set_attribute @entity, :street, "Main St."

    assert_nil @db.get_cached_entity(@entity)
  end
end
