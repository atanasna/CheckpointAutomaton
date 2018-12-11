require "ipaddress"
require_relative "CpObject.rb"

class CpNetwork < CpObject
    attr_reader :name, :net

    def initialize name, network
        super name
        @net = network
    end

    def address
        return @net
    end

    def broadcast
        return @net.broadcast
    end

    def prefix
        return @net.prefix
    end

    def include? input 
        if input.class.name == "IPAddress::IPv4"
            return @net.include? input
        end
        if input.class.name == "CpHost"
            return @net.include? input.ip
        end
        if input.class.name == "CpNetwork"
            return @net.include? input.net
        end
        if input.class.name == "CpRange"
            return (@net.include? input.first and @net.include? input.last )
        end
    end
end