require "ipaddress"

class CpNetwork < CpObject
    attr_reader :name, :address

    def initialize name, address
        super name
        @address = address
    end

    def broadcast
        return @address.broadcast
    end

    def prefix
        return @address.prefix
    end

    # Based on address
    def include? input 
        case input.class.name
        when "IPAddress::IPv4"
            return @address.include? input
        when "CpHost"
            return @address.include? input.address
        when "CpNetwork"
            return @address.include? input.address
        when "CpRange"
            return (@address.include? input.first and @address.include? input.last )
        when "CpGroup"
            if input.elements.empty?
                return false
            end
            
            input.expand.each do |el|
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
    def ip_equal? input
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