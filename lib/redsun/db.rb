require 'sqlite3'

module RedSun
  class DB
    def initialize(path)
      init = !File.exists?(path)
      @sqlite = SQLite3::Database.new path

      if init
        @sqlite.query "CREATE TABLE attributes (id integer primary key, taction integer key, key string, attribute string, value string);"
        @sqlite.query "CREATE TABLE transactions (id integer primary key, timestamp string);"
        @sqlite.query "CREATE TABLE models (id integer primary key, key string, taction integer);"
      end

      @cache = Hash.new { |h,k| h[k] = {} }
      @model_cache = {}
      @transactions = 0
    end

    def get(key, attribute)
      if v = @cache[key][attribute]
        v.first
      else
        res = @sqlite.query "select value,taction from attributes where key='#{key}' and attribute='#{attribute}'"
        if s = res.next
          @cache[key][attribute] = s
          return s.first
        end

        res.close

        nil
      end
    end

    def get_transaction(key, attribute)
      if v = @cache[key][attribute]
        v.last
      end
    end

    def new_transaction
      ts = Time.now.to_f.to_s
      @sqlite.query "insert into transactions (timestamp) values (#{ts})"
      @sqlite.last_insert_row_id
    end

    def set_attribute(key, attribute, value)
      t = new_transaction

      @cache[key][attribute] = [value, t]
      @sqlite.query "insert into attributes (taction,key,attribute,value) values ('#{t}', '#{key}', '#{attribute}', '#{value}')"

      @sqlite.query "insert into models (taction,key) values ('#{t}', '#{key}')"

      t
    end

    def set_model(key, mod)
      t = new_transaction

      mod.each do |attribute, value|
        @cache[key][attribute] = [value, t]
        @sqlite.query "insert into attributes (taction,key,attribute,value) values ('#{t}', '#{key}', '#{attribute}', '#{value}')"
      end

      @sqlite.query "insert into models (taction,key) values ('#{t}', '#{key}')"

      @model_cache[key] = t

      t
    end

    def get_model(key)
      if mod = get_cached_model(key)
        return mod
      end

      res = @sqlite.query "select attribute,value,taction from attributes where key='#{key}' order by taction"

      mod = {}

      res.each do |name,value,t|
        mod[name.to_sym] = value
      end

      res.close

      mod
    end

    def get_model_at(key, at)
      res = @sqlite.query "select attribute,value,taction from attributes where key='#{key}' and taction <= '#{at}' order by taction"

      mod = {}

      res.each do |name,value,t|
        mod[name.to_sym] = value
      end

      res.close

      mod
    end

    def get_cached_model(key)
      r = @sqlite.query "select taction from models where key='#{key}' order by taction desc limit 1"

      v, = r.next

      r.close

      return nil if @model_cache[key] != v

      mod = {}

      @cache[key].each do |k,vt|
        mod[k] = vt.first
      end

      mod
    end
  end
end
