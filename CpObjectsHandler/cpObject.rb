class CpObject
    attr_accessor :name, :raw

    def initialize name
        @name = name
        @raw = Array.new
    end

    def color=color
        color_line = raw.find{|line| line.match(/:color/)}

        case color
        when "black" 
            color_line.gsub!(/\(.+\)/,'(black)') 
        when "olive" 
            color_line.gsub!(/\(.+\)/,'("olive drab")') 
        when "forest green" 
            color_line.gsub!(/\(.+\)/,'("forest green")') 
        when "sea green" 
            color_line.gsub!(/\(.+\)/,'(darkseagreen3)') 
        when "light green" 
            color_line.gsub!(/\(.+\)/,'(green)') 
        when "yellow" 
            color_line.gsub!(/\(.+\)/,'(yellow)') 
        when "orange" 
            color_line.gsub!(/\(.+\)/,'(orange)') 
        when "gold" 
            color_line.gsub!(/\(.+\)/,'(gold)') 
        when "dark gold" 
            color_line.gsub!(/\(.+\)/,'(gold3)') 
        when "blue" 
            color_line.gsub!(/\(.+\)/,'(dodgerblue3)') 
        when "dark blue" 
            color_line.gsub!(/\(.+\)/,'(blue1)') 
        when "sky blue" 
            color_line.gsub!(/\(.+\)/,'(deepskyblue1)') 
        when "turquoise" 
            color_line.gsub!(/\(.+\)/,'(lightseagreen)') 
        when "pink" 
            color_line.gsub!(/\(.+\)/,'("deep pink")') 
        when "purple" 
            color_line.gsub!(/\(.+\)/,'("medium orchid")') 
        when "red" 
            color_line.gsub!(/\(.+\)/,'(red)')
        when "firebrick" 
            color_line.gsub!(/\(.+\)/,'(firebrick)')
        else
            color_line.gsub!(/\(.+\)/,'(black)')
        end
    end
    
    def color
        return @raw.find{|line| line.match(/:color/)}.match(/\((.*?)\)/i).captures.first
    end

    # for sorting
    def <=> (cp_object)
        @name <=> cp_object.name
    end
end