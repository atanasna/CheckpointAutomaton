require_relative "../helpers.rb"
require_relative "cpHost.rb"
require_relative "cpGroup.rb"
require_relative "cpNetwork.rb"
require_relative "cpRange.rb"

class CpObjectsHandler
    include ParserHelpers
    
    attr_reader :objects

    def initialize filename
        
        @objects = Array.new

        @objects.push CpNetwork.new("Any", IPAddress("0.0.0.0/0"))

        load filename
    end

    def load filename
        groups_raw = Array.new

        raw_file = File.read(filename).split(/\n+/)
        net_objects = open_tag_objects raw_file,"network_objects"
        raw_objects = open_tag_objects net_objects.first, "", false

        #Load simple objects (Hosts, Networks, Ranges)
        raw_objects.each do |obj|
            # Hosts
            if obj.find{|l| l.match(/:type \(host\)|:type \(gateway\)/)} 
                name = obj.find{|l| l.match(/:name \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                ip = obj.find{|l| l.match(/:ipaddr \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                ip = IPAddress ip
                host = CpHost.new name,ip
                #pp "#{host.class.name} : #{host.name} : #{host.ip}"
                #@hosts.push host
                @objects.push host
            end
            # Networks
            if obj.find{|l| l.match(/:type \(network\)/)} 
                name = obj.find{|l| l.match(/:name \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                ip = obj.find{|l| l.match(/:ipaddr \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                mask = obj.find{|l| l.match(/:netmask \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                net = IPAddress "#{ip}/#{mask}"
                network = CpNetwork.new name,net
                #pp "#{network.class.name} : #{network.name} : #{network.address}/#{network.prefix}"
                #@nets.push network
                @objects.push network
            end

            # Ranges
            if obj.find{|l| l.match(/:type \(machines_range\)/)} 
                name = obj.find{|l| l.match(/:name \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                first_ip = obj.find{|l| l.match(/:ipaddr_first \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                last_ip = obj.find{|l| l.match(/:ipaddr_last \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                first_ip = IPAddress first_ip
                last_ip = IPAddress last_ip
                range = CpRange.new name,first_ip,last_ip
                #pp "#{range.class.name} : #{range.name} : #{range.first} : #{range.last}"
                #@ranges.push range
                @objects.push range
            end

            # Groups
            if obj.find{|l| l.match(/:type \(group\)/)} 
                groups_raw.push obj
            end
        end

        groups_raw.each do |group_raw|
            name = group_raw.find{|l| l.match(/:name \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
            group = CpGroup.new name
            #pp "========== #{group.name} ==========="
            elements_names = group_raw.find_all{|l| l.match(/:Name \(.*?\)/)}
            elements_names.each do |el_name|
                    el_name = el_name.match(/\((.*?)\)/i).captures.first
                    #pp el_name
                    obj = @objects.find{|n| n.name == el_name}

                    if obj.nil?
                        group.unknown.push el_name
                        #pp "U: #{group.name} - #{el_name}"
                        #pp node_name
                    else
                        if obj.class.name == "CpGroup"
                            #pp "G: #{group.name} - #{el_name}"
                            group.unknown.push el_name
                        else
                            group.add obj
                        end
                    end

            end
            #@groups.push group
            @objects.push group  
        end

        groups.each do |group|
            if group.unknown.size != 0
                group.elements += solve_group group
            end
            group.elements.uniq!
        end
    end

    # HELPERS
    def solve_group group
        elements = Array.new
        #pp "checking #{group.name}"
        #pp group.unknown
        if group.unknown != 0
            group.unknown.each do |un|
                in_group = groups.find{|g| g.name == un}
                #pp "going in: #{in_group.name}"
                elements += solve_group in_group
            end
            group.unknown = Array.new
        else
            return group.elements
        end

        return elements
    end

    def networks
        return @objects.find_all{|obj| obj.class.name == "CpNetwork"}
    end

    def hosts
        return @objects.find_all{|obj| obj.class.name == "CpHost"}
    end

    def ranges
        return @objects.find_all{|obj| obj.class.name == "CpRange"}
    end

    def groups
        return @objects.find_all{|obj| obj.class.name == "CpGroup"}
    end
end