require "ipaddress"
require_relative "CpObject.rb"

class CpNetwork < CpObject
    attr_reader :name

    def initialize name, network
        super name
        @network = network
    end

    def address
        return @network
    end

    def broadcast
        return @network.broadcast
    end

    def prefix
        return @network.prefix
    end

    def include? input 
        case input.class.name
        when "IPAddress::IPv4"
            return @network.include? input
        when "CpHost"
            return @network.include? input.ip
        when "CpNetwork"
            return @network.include? input.address
        when "CpRange"
            return (@network.include? input.first and @network.include? input.last )
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
end