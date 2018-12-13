require_relative "../helpers.rb"

class CpPolicyEntry
    include ParserHelpers
    attr_accessor :raw, :name, :position

    def initialize raw, position
        @raw = raw
        @name = String.new
        @position = position
    end

    def parse_tag tag_name
        elements = Array.new
        open_tag(@raw, tag_name).each do |el|
            if el.is_a? String
                return el
            else
                elements +=  el.join(' ').scan(/:Name \((.*?)\)/)
            end
        end
        return elements.map{|el| el.join('')}
    end

    def print
        pp "@position: #{@position}"
        pp "@name: #{@name}"
    end

    # for sorting
    def <=> (entry)
        @position <=> entry.position
    end
end