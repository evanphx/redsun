module RedSun
  class QueryEngine
    def initialize
      @data = []
    end

    def load(data)
      @data = data
    end

    def check(a, b)
      return true if a.kind_of? Symbol
      a == b
    end

    def check2(e, a, b)
      if a.kind_of? Symbol
        if c = e[a]
          return c == b
        end
      end

      a == b
    end

    def find(match, which)
      if match[0].kind_of? Array
        find_from_many(@data, match, which)
      else
        find_from_one(@data, match, which)
      end

    end

    def find_from_one(data, match, which)
      found = []

      pos = which.map { |x| match.index(x) }

      data.each do |eav|
        m = check(match[0], eav[0]) && 
            check(match[1], eav[1]) &&
            check(match[2], eav[2])

        if m
          found << eav.values_at(*pos)
        end
      end

      found
    end

    def find_entities(source, ids)
      source.find_all do |eav|
        ids.include? eav[0]
      end
    end

    require 'pp'

    class FindEntities
      def initialize(source, attr)
        @source = source
        @attr = attr
      end

      def datoms
        @source.select do |e,a,v|
          a == @attr
        end
      end

      def entities
        datoms.map { |x| x[0] }
      end
    end

    class FilterEntities
      def initialize(source, attr, data)
        @source = source
        @attr = attr
        @data = data
      end

      def datoms
        eids = @source.entities

        @data.select do |e,a,v|
          eids.include?(e) && a == @attr
        end
      end

      def entites
        datoms.map { |x| x[0] }
      end

      def values
        datoms.map { |x| x[2] }
      end
    end

    class SelectEntities
      def initialize(source, attr, data)
        @source = source
        @attr = attr
        @data = data
      end

      def datoms
        eids = @source.values

        @data.select do |e,a,v|
          eids.include?(e) && a == @attr
        end
      end

      def values
        datoms.map { |x| x[2] }
      end
    end

    class DeriveValue
      def initialize(parent)
        @parent = parent
      end

      def values
        @parent.datoms.map { |x| x[2] }
      end
    end

    def find_from_many(data, matches, which)
      vars = {}

      matches.each do |m|
        case cur = vars[m[0]]
        when nil
          e = FindEntities.new data, m[1]
        when FindEntities
          e = FilterEntities.new cur, m[1], data
        when DeriveValue
          e = SelectEntities.new cur, m[1], data
        else
          raise "Unknown type for #{m[0]}"
        end

        vars[m[0]] = e
        if m[2].kind_of? Symbol
          vars[m[2]] = DeriveValue.new e
        end
      end

      vals = which.map { |w| vars[w].values }

      p which => vals
      pp vars

      vals.shift.zip(*vals)
    end

    def find_from_many2(data, matches, which)
      entities = {}
      values = {}

      matches.each do |m|
        puts "==========="
        p :match => m
        s = nil

        assign = nil

        if m[0].kind_of? Symbol
          assign = m[0]

          if entities.key? m[0]
            e = entities[m[0]]
            s = find_entities data, e
          elsif values.key? m[0]
            e = values[m[0]]
            s = find_entities data, e
          end
        end

        if s
          pp :prune => [m,s]
          s.delete_if do |eav|
            !check(m[0], eav[0]) || 
            !check(m[1], eav[1]) ||
            !check(m[2], eav[2])
          end
        else
          s = []

          data.each do |eav|
            s << eav if check(m[0], eav[0]) &&
                        check(m[1], eav[1]) &&
                        check(m[2], eav[2])

          end
          
        end
        
        entities[assign] = s.map { |x| x[0] } if assign

        if m[2].kind_of? Symbol
          values[m[2]] = s.map { |x| x[2] }
        end
        pp s
        pp entities
        pp values

      end

      pp entities
      pp values
    end

    # def find_from_many_old(data, matches, which)

      # entities = Hash.new { |h,k| = [] }

      # matches.each do |m|
        # if m[0].kind_of? Symbol
          # entities[m[0]] << m
        # end
      # end

      # expanded = {}

      # entities.each do |e,c|
        # expanded[e] = 
      # end

      # vars = {}

      # reduced = []

      # env = {}

      # matches.each do |match|
        # which.map { |x| [x, match.index(x)] }.each do |name,x|
          # vars[name] ||= x
        # end

        # data.each do |eav|
          # m = check2(env, match[0], eav[0]) && 
              # check2(env, match[1], eav[1]) &&
              # check2(env, match[2], eav[2])

          # reduced << eav if m
        # end
      # end

      # p reduced

      # pos = vars.values
      # data.map { |eav| eav.values_at(*pos) }
    # end
  end
end
