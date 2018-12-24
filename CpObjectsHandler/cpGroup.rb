require "ipaddress"
require_relative "CpObject.rb"

class CpGroup < CpObject
    attr_accessor :name, :elements, :unknown
    
    def initialize name
        super name
        @elements = Array.new
        @expandable = 0
    end

    def add element
        @elements.push element
        @elements.uniq!
    end

    def remove element
        @elements.delete element
    end

    def include? object
        expand.each do |el|
            if el.include? object
                return true
            end
        end
        return false
    end

    def expand
        expanded_elements = Array.new
        
        @elements.each do |el|
            if el.class == CpGroup
                expanded_elements += el.expand
            else
                expanded_elements.push el
            end
        end
        
        return expanded_elements.uniq
    end
end
