class CpObject
    attr_accessor :name, :raw

    def initialize name
        @name = name
        @raw = Array.new
    end

    def color=color
        color_line = raw.find{|line| line.match(/:color/)}
        if color=="Black" then color_line.gsub!(/\(.+\)/,"(black)") end
        if color=="Purple" then color_line.gsub!(/\(.+\)/,"(\"Deep Purple\")") end
    end
    
    def color
        return @raw.find{|line| line.match(/:color/)}
    end

    # for sorting
    def <=> (cp_object)
        @name <=> cp_object.name
    end
end