require "ipaddress"
require_relative "CpObject.rb"

class CpHost < CpObject
    attr_reader :name, :address

    def initialize name, address
        super name
        @name = name
        @address = address
        @raw = self.class.raw_template name, address
    end

    def ip_include? object
        case object.class.name
        when "IPAddress::IPv4"
            return @address == object
        when "CpHost"
            return @address == object.address
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

    def self.raw_template name, address
        raw = Array.new
        hex = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
        uid = "#{(0..7).map{hex[rand(16)]}.join}-#{(0..3).map{hex[rand(16)]}.join}-#{(0..3).map{hex[rand(16)]}.join}-#{(0..3).map{hex[rand(16)]}.join}-#{(0..11).map{hex[rand(16)]}.join}"
        time = Time.now
        raw.push "\t\t: (#{name}"
        raw.push "\t\t\t:AdminInfo ("
        raw.push "\t\t\t\t:chkpf_uid (\"{#{uid}}\")"
        raw.push "\t\t\t\t:ClassName (host_plain)"
        raw.push "\t\t\t\t:table (network_objects)"
        raw.push "\t\t\t\t:Wiznum (-1)"
        raw.push "\t\t\t\t:LastModified ("
        raw.push "\t\t\t\t\t:Time (\"#{time.strftime('%c')}\")"
        raw.push "\t\t\t\t\t:last_modified_utc (#{time.to_i})"
        raw.push "\t\t\t\t\t:By (\"Check Point Security Management Server Update Process\")"
        raw.push "\t\t\t\t\t:From (localhost)"
        raw.push "\t\t\t\t)"
        raw.push "\t\t\t\t:icon (\"NetworkObjects/Nodes/Host\")"
        raw.push "\t\t\t\t:name (#{name})"
        raw.push "\t\t\t)"
        raw.push "\t\t\t:certificates ()"
        raw.push "\t\t\t:edges ()"
        raw.push "\t\t\t:interfaces ()"
        raw.push "\t\t\t:DAG (false)"
        raw.push "\t\t\t:NAT ()"
        raw.push "\t\t\t:read_community ()"
        raw.push "\t\t\t:sysContact ()"
        raw.push "\t\t\t:sysDescr ()"
        raw.push "\t\t\t:sysLocation ()"
        raw.push "\t\t\t:sysName ()"
        raw.push "\t\t\t:write_community ()"
        raw.push "\t\t\t:SNMP ("
        raw.push "\t\t\t\t:AdminInfo ("
        raw.push "\t\t\t\t\t:chkpf_uid (\"{#{uid}}\")"
        raw.push "\t\t\t\t\t:ClassName (SNMP)"
        raw.push "\t\t\t\t)"
        raw.push "\t\t\t)"
        raw.push "\t\t\t:VPN ()"
        raw.push "\t\t\t:add_adtr_rule (false)"
        raw.push "\t\t\t:additional_products ()"
        raw.push "\t\t\t:addr_type_indication (IPv4)"
        raw.push "\t\t\t:color (black)"
        raw.push "\t\t\t:comments ()"
        raw.push "\t\t\t:connectra (false)"
        raw.push "\t\t\t:connectra_settings ()"
        raw.push "\t\t\t:cp_products_installed (false)"
        raw.push "\t\t\t:data_source (not-installed)"
        raw.push "\t\t\t:data_source_settings ()"
        raw.push "\t\t\t:enforce_gtp_rate_limit (false)"
        raw.push "\t\t\t:firewall (not-installed)"
        raw.push "\t\t\t:floodgate (not-installed)"
        raw.push "\t\t\t:gtp_rate_limit (2048)"
        raw.push "\t\t\t:ipaddr (#{address})"
        raw.push "\t\t\t:ipaddr6 ()"
        raw.push "\t\t\t:macAddress ()"
        raw.push "\t\t\t:os_info ()"
        raw.push "\t\t\t:type (host)"
        return raw
    end
end