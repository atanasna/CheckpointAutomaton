require "ipaddress"
require_relative "CpObject.rb"

class CpRange < CpObject
    attr_reader :name, :first, :last

    def initialize name, first_ip, last_ip
        super name
        @first = first_ip
        @last = last_ip
        @raw = self.class.raw_template name, first_ip, last_ip
    end

    # Based on address
    def ip_include? object
        case object.class.name
        when "IPAddress::IPv4"
            return (@first.to_i <= object.to_i and @last.to_i >= object.to_i)
        when "CpHost"
            return (@first.to_i <= object.address.to_i and @last.to_i >= object.address.to_i)
        when "CpNetwork"
            return (@first.to_i <= object.address.to_i and @last.to_i >= object.broadcast.to_i)
        when "CpRange"
            return (@first.to_i <= object.first.to_i and @last.to_i >= object.last.to_i)
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

    # Based on address
    def ip_equal? object
        case object.class.name
        when "IPAddress::IPv4"
            return @first == object && @last == object
        when "CpHost"
            return @first == object.address && @last == object.address
        when "CpNetwork"
            return @first == object.address && @last == object.address
        when "CpRange"
            return @first == object.first && @last == object.last
        when "CpGroup"
            return false
        else
            return false    
        end
    end

    def self.raw_template name, first_ip, last_ip
        raw = Array.new
        hex = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
        uid = "#{(0..7).map{hex[rand(16)]}.join}-#{(0..3).map{hex[rand(16)]}.join}-#{(0..3).map{hex[rand(16)]}.join}-#{(0..3).map{hex[rand(16)]}.join}-#{(0..11).map{hex[rand(16)]}.join}"
        time = Time.now
        raw.push "\t\t: (#{name}"
        raw.push "\t\t\t:AdminInfo ("
        raw.push "\t\t\t\t:LastModified ("
        raw.push "\t\t\t\t\t:Time (\"#{time.strftime('%c')}\")"
        raw.push "\t\t\t\t\t:last_modified_utc (#{time.to_i})"
        raw.push "\t\t\t\t\t:By (\"Check Point Security Management Server Update Process\")"
        raw.push "\t\t\t\t\t:From (localhost)"
        raw.push "\t\t\t\t)"
        raw.push "\t\t\t\t:chkpf_uid (\"{#{uid}}\")"
        raw.push "\t\t\t\t:ClassName (address_range)"
        raw.push "\t\t\t\t:table (network_objects)"
        raw.push "\t\t\t\t:Hidden (true)"
        raw.push "\t\t\t\t:Deleteable (false)"
        raw.push "\t\t\t\t:Renameable (false)"
        raw.push "\t\t\t\t:icon (\"NetworkObjects/AddressRanges/AddressRange\")"
        raw.push "\t\t\t\t:name (#{name})"
        raw.push "\t\t\t)"
        raw.push "\t\t\t:edges ()"
        raw.push "\t\t\t:NAT ()"
        raw.push "\t\t\t:add_adtr_rule (false)"
        raw.push "\t\t\t:addr_type_indication (IPv4)"
        raw.push "\t\t\t:color (black)"
        raw.push "\t\t\t:comments ()"
        raw.push "\t\t\t:ipaddr_first (#{first_ip})"
        raw.push "\t\t\t:ipaddr_first6 ()"
        raw.push "\t\t\t:ipaddr_last (#{last_ip})"
        raw.push "\t\t\t:ipaddr_last6 ()"
        raw.push "\t\t\t:type (machines_range)"
        return raw
    end
end