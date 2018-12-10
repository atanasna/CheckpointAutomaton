require "ipaddress"
require_relative "cpObject.rb"

class CpGroup < CpObject
    attr_accessor :name, :elements, :unknown
    
    def initialize name
        super name
        @elements = Array.new
        @unknown = Array.new
    end

    def add element
        @elements.push element
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