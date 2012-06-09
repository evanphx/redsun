require 'sqlite3'

module RedSun
  class DB
    def initialize(path)
      init = !File.exists?(path)
      @sqlite = SQLite3::Database.new path

      if init
        @sqlite.query "CREATE TABLE attributes (id integer primary key, taction integer key, entity integer, attribute string, value string);"
        @sqlite.query "CREATE TABLE transactions (id integer primary key, timestamp string);"
        @sqlite.query "CREATE TABLE entity_log (id integer primary key, entity integer, taction integer);"
      end

      @cache = Hash.new { |h,k| h[k] = {} }
      @entity_cache = {}
      @transactions = 0
    end

    def get(entity, attribute)
      if v = @cache[entity][attribute]
        v.first
      else
        res = @sqlite.query "select value,taction from attributes where entity='#{entity}' and attribute='#{attribute}'"
        if s = res.next
          @cache[entity][attribute] = s
          return s.first
        end

        res.close

        nil
      end
    end

    def get_transaction(entity, attribute)
      if v = @cache[entity][attribute]
        v.last
      end
    end

    def new_transaction
      ts = Time.now.to_f.to_s
      @sqlite.query "insert into transactions (timestamp) values (#{ts})"
      @sqlite.last_insert_row_id
    end

    def set_attribute(entity, attribute, value)
      t = new_transaction

      @cache[entity][attribute] = [value, t]
      @sqlite.query "insert into attributes (taction,entity,attribute,value) values ('#{t}', '#{entity}', '#{attribute}', '#{value}')"

      @sqlite.query "insert into entity_log (taction,entity) values ('#{t}', '#{entity}')"

      t
    end

    def set_entity(entity, mod)
      t = new_transaction

      mod.each do |attribute, value|
        @cache[entity][attribute] = [value, t]
        @sqlite.query "insert into attributes (taction,entity,attribute,value) values ('#{t}', '#{entity}', '#{attribute}', '#{value}')"
      end

      @sqlite.query "insert into entity_log (taction,entity) values ('#{t}', '#{entity}')"

      @entity_cache[entity] = t

      t
    end

    def get_entity(entity)
      if mod = get_cached_entity(entity)
        return mod
      end

      res = @sqlite.query "select attribute,value,taction from attributes where entity='#{entity}' order by taction"

      mod = {}

      res.each do |name,value,t|
        mod[name.to_sym] = value
      end

      res.close

      mod
    end

    def get_entity_at(entity, at)
      res = @sqlite.query "select attribute,value,taction from attributes where entity='#{entity}' and taction <= '#{at}' order by taction"

      mod = {}

      res.each do |name,value,t|
        mod[name.to_sym] = value
      end

      res.close

      mod
    end

    def get_cached_entity(entity)
      r = @sqlite.query "select taction from entity_log where entity='#{entity}' order by taction desc limit 1"

      v, = r.next

      r.close

      return nil if @entity_cache[entity] != v

      mod = {}

      @cache[entity].each do |k,vt|
        mod[k] = vt.first
      end

      mod
    end
  end
end
