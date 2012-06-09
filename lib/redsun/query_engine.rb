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

    def find_from_many(data, matches, which)
      vars = {}

      matches.each do |match|
        which.map { |x| [x, match.index(x)] }.each do |name,x|
          vars[name] ||= x
        end

        nd = []

        data.each do |eav|
          m = check(match[0], eav[0]) && 
              check(match[1], eav[1]) &&
              check(match[2], eav[2])

          nd << eav if m
        end

        data = nd
      end

      pos = vars.values
      data.map { |eav| eav.values_at(*pos) }
    end
  end
end
