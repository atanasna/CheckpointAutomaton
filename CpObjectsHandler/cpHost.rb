require "ipaddress"
require_relative "cpObject.rb"

class CpHost < CpObject
    attr_reader :name, :ip

    def initialize name, ip
        super name
        @name = name
        @ip = ip
    end

    def include? input
        if input.class.name == "IPAddress::IPv4"
            return @ip == input
        end
        if input.class.name == "CpHost"
            return @ip == input.ip
        end
        if input.class.name == "CpNetwork"
            return false
        end
        if input.class.name == "CpRange"
            return false
        end
    end
end