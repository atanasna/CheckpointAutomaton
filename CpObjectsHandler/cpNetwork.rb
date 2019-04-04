require "ipaddress"

class CpNetwork < CpObject
    attr_reader :name, :address

    def initialize name, address
        super name
        @address = address
        @raw = self.class.raw_template name, address
    end

    def broadcast
        return @address.broadcast
    end

    def prefix
        return @address.prefix
    end

    def ip_include? object 
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
                if not ip_include? el
                    return false
                end
            end
            return true
        else
            return false    
        end
    end

    def ip_equal? object
        case object.class.name
        when "IPAddress::IPv4"
            return @address == object
        when "CpHost"
            return @address == object.address
        when "CpNetwork"
            return @address == object.address
        when "CpRange"
            return @address == object.first && @address == object.last
        when "CpGroup"
            return false
        else
            return false
        end
    end

    def self.raw_template name, address
        raw = Array.new
        hex = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
        uid = "#{(0..7).map{hex[rand(16)]}.join}-#{(0..3).map{hex[rand(16)]}.join}-#{(0..3).map{hex[rand(16)]}.join}-#{(0..3).map{hex[rand(16)]}.join}-#{(0..11).map{hex[rand(16)]}.join}"
        time = Time.now
        raw.push "\t\t: (#{name}"
        raw.push "\t\t\t:AdminInfo ("
        raw.push "\t\t\t\t:chkpf_uid (\"{#{uid}}\")"
        raw.push "\t\t\t\t:ClassName (network)"
        raw.push "\t\t\t\t:table (network_objects)"
        raw.push "\t\t\t\t:Wiznum (-1)"
        raw.push "\t\t\t\t:LastModified ("
        raw.push "\t\t\t\t\t:Time (\"#{time.strftime('%c')}\")"
        raw.push "\t\t\t\t\t:last_modified_utc (#{time.to_i})"
        raw.push "\t\t\t\t\t:By (\"Check Point Security Management Server Update Process\")"
        raw.push "\t\t\t\t\t:From (localhost)"
        raw.push "\t\t\t\t)"
        raw.push "\t\t\t\t:icon (\"NetworkObjects/Network/Network\")"
        raw.push "\t\t\t\t:name (#{name})"
        raw.push "\t\t\t)"
        raw.push "\t\t\t:edges ()"
        raw.push "\t\t\t:use_as_wildcard_netmask (false)"
        raw.push "\t\t\t:NAT ()"
        raw.push "\t\t\t:add_adtr_rule (false)"
        raw.push "\t\t\t:addr_type_indication (IPv4)"
        raw.push "\t\t\t:broadcast (allow)"
        raw.push "\t\t\t:color (black)"
        raw.push "\t\t\t:comments ()"
        raw.push "\t\t\t:ipaddr (#{address})"
        raw.push "\t\t\t:ipaddr6 ()"
        raw.push "\t\t\t:location (internal)"
        raw.push "\t\t\t:location_desc ()"
        raw.push "\t\t\t:macAddress ()"
        raw.push "\t\t\t:netmask (#{address.netmask})"
        raw.push "\t\t\t:netmask6 ()"
        raw.push "\t\t\t:type (network)"
        return raw
    end
end