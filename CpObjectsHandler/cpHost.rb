require "ipaddress"
require_relative "CpObject.rb"

class CpHost < CpObject
    attr_reader :name, :ip

    def initialize name, ip
        super name
        @name = name
        @ip = ip
    end

    def include? input
        case input.class.name
        when "IPAddress::IPv4"
            return @ip == input
        when "CpHost"
            return @ip == input.ip
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
end