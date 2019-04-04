require "ipaddress"
require_relative "CpObject.rb"

class CpGroup < CpObject
    attr_accessor :name, :elements, :unknown
    
    def initialize name
        super name
        @elements = Array.new
    end

    def add object
        @elements.push object
        @elements.uniq!
    end

    def remove object
        @elements.delete object
    end

    def include? object
        elements.each do |el|
            if el.equal? object
                return true
            end
        end

        return false
    end
    
    def ip_include? object
        expand.each do |el|
            if el.ip_include? object
                return true
            end
        end

        return false
    end

    def ip_equal? object
        case object.class.name
        when "CpGroup"
            pri_elements = expand.sort
            sec_elements = object.expand.sort
        
            if not pri_elements.size == sec_elements.size
                #puts "~ NOT Duplicated groups: #{@name} - #{object.name}"
                return false
            end
        
            pri_elements.size.times do |i|
                if not pri_elements[i].ip_equal? sec_elements[i]
                    return false
                end
            end
        
            return true
        else
            return false    
        end
    end

    def expand
        expanded_elements = Array.new
        
        @elements.each do |el|
            if el.class.name == "CpGroup"
                expanded_elements += el.expand
            else
                expanded_elements.push el
            end
        end
        
        return expanded_elements.uniq
    end

end
