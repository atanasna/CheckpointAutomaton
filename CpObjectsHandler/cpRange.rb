require "ipaddress"
require_relative "CpObject.rb"

class CpRange < CpObject
    attr_reader :name, :first, :last

    def initialize name, first_ip, last_ip
        super name
        @first = first_ip
        @last = last_ip
    end

    def include? input
        if input.class.name == "IPAddress::IPv4"
            return (@first.to_i <= input.to_i and @last.to_i >= input.to_i)
        end
        if input.class.name == "CpHost"
            return (@first.to_i <= input.ip.to_i and @last.to_i >= input.ip.to_i)
        end
        if input.class.name == "CpNetwork"
            return (@first.to_i <= input.address.to_i and @last.to_i >= input.broadcast.to_i)
        end
        if input.class.name == "CpRange"
            return (@first.to_i <= input.first.to_i and @last.to_i >= input.last.to_i)
        end
    end
end