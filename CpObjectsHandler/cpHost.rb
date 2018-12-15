require "ipaddress"
require_relative "CpObject.rb"

class CpHost < CpObject
    attr_reader :name, :address

    def initialize name, address
        super name
        @name = name
        @address = address
    end

    # Based on address
    def include? input
        case input.class.name
        when "IPAddress::IPv4"
            return @address == input
        when "CpHost"
            return @address == input.address
        when "CpNetwork"
            return false
        when "CpRange"
            return false
        when "CpGroup"
            return false
        else
            return false    
        end
    end

    # Based on Address
    def equal? input
        case input.class.name
        when "IPAddress::IPv4"
            return @address == input
        when "CpHost"
            return @address == input.address
        when "CpNetwork"
            return @address == input.address
        when "CpRange"
            return @address == input.first && @address == input.last
        when "CpGroup"
            return false
        else
            return false    
        end
    end
end