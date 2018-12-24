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
    def include? object 
        case object.class.name
        when "IPAddress::IPv4"
            return @address.include? object
        when "CpHost"
            return @address.include? object.address
        when "CpNetwork"
            return @address.include? object.address
        when "CpRange"
            return (@address.include? object.first and @address.include? object.last )
        when "CpGroup"
            if object.elements.empty?
                return false
            end
            
            object.expand.each do |el|
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