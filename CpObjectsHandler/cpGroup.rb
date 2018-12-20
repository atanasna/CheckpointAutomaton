require "ipaddress"
require_relative "CpObject.rb"

class CpGroup < CpObject
    attr_accessor :name, :elements, :original, :unknown
    
    def initialize name
        super name
        @elements = Array.new
        @original = Array.new
        @unknown = Array.new
    end

    def add element
        @elements.push element
        @elements.uniq!
    end

    def remove element
        @elements.delete element
    end

    def include? input
        @elements.each do |el|
            if el.include? input
                return true
            end
        end
        return false
    end
end