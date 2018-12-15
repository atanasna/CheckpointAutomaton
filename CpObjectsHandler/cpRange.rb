require "ipaddress"
require_relative "CpObject.rb"

class CpRange < CpObject
    attr_reader :name, :first, :last

    def initialize name, first_ip, last_ip
        super name
        @first = first_ip
        @last = last_ip
    end

    # Based on address
    def include? input
        case input.class.name
        when "IPAddress::IPv4"
            return (@first.to_i <= input.to_i and @last.to_i >= input.to_i)
        when "CpHost"
            return (@first.to_i <= input.address.to_i and @last.to_i >= input.address.to_i)
        when "CpNetwork"
            return (@first.to_i <= input.address.to_i and @last.to_i >= input.broadcast.to_i)
        when "CpRange"
            return (@first.to_i <= input.first.to_i and @last.to_i >= input.last.to_i)
        when "CpGroup"
            if input.elements.empty?
                return false
            end

            input.elements.each do |el|
                if not include? el
                    return false
                end
            end
            
            return true
        else
            return false    
        end
    end

    # Based on address
    def equal? input
        case input.class.name
        when "IPAddress::IPv4"
            return @first == input && @last == input
        when "CpHost"
            return @first == input.address && @last == input.address
        when "CpNetwork"
            return @first == input.address && @last == input.address
        when "CpRange"
            return @first == input.first && @last == input.last
        when "CpGroup"
            return false
        else
            return false    
        end
    end
end