require_relative "../helpers.rb"
require_relative "CpHost.rb"
require_relative "CpGroup.rb"
require_relative "CpNetwork.rb"
require_relative "CpRange.rb"

class CpObjectsHandler
    include ParserHelpers
    
    attr_reader :objects, :raw

    def initialize filename
        
        @objects = Array.new
        @raw = Array.new
        #@objects.push CpNetwork.new("Any", IPAddress("0.0.0.0/0"))

        load filename
    end

    # Accessors
    def networks
        return @objects.find_all{|obj| obj.class.name == "CpNetwork"}
    end

    def gateways
        return @objects.find_all{|obj| obj.class.name == "CpGateway"}
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

    # Helpers
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

    def generate_raw 
        network_objects_start_index = @raw.index(@raw.find{ |l| l[/\t:network_objects \(/]}) + 1
        network_objects_end_index = @raw.index(@raw.find{ |l| l[/\t:vs_slot_objects \(/]}) + 1

        start_new_raw = @raw.slice 0,network_objects_start_index
        end_new_raw = @raw.slice network_objects_end_index-2, @raw.count-1

        new_objects = Array.new
        @objects.each do |object|
            new_objects.push "\t\t: ("+object.name
            new_objects += object.raw
            new_objects.push "\t\t)"
        end

        return start_new_raw + new_objects + end_new_raw
    end

    def load filename
        @raw = File.read(filename).split(/\n+/)
        net_objects = open_tag @raw,"network_objects"
        objects_raw = open_tag net_objects.first, "", false

        #Load simple objects (Hosts, Networks, Ranges)
        objects_raw.each do |obj_raw|
                obj_name = obj_raw.find{|l| l.match(/:name \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                
                obj_type = obj_raw.find{|l| l.match(/^\t{3}:type \((.*?)\)/i)}.match(/\((.*?)\)/i).captures.first

                case obj_type
                when "host","gateway"
                    ip = obj_raw.find{|l| l.match(/:ipaddr \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                    ip = IPAddress ip
                    host = CpHost.new obj_name,ip
                    host.raw = obj_raw
                    @objects.push host

                when "network"
                    ip = obj_raw.find{|l| l.match(/:ipaddr \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                    mask = obj_raw.find{|l| l.match(/:netmask \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                    net = IPAddress "#{ip}/#{mask}"
                    network = CpNetwork.new obj_name,net
                    network.raw = obj_raw
                    @objects.push network

                when "machines_range"
                    first_ip = obj_raw.find{|l| l.match(/:ipaddr_first \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                    last_ip = obj_raw.find{|l| l.match(/:ipaddr_last \(.*?\)/)}.match(/\((.*?)\)/i).captures.first
                    first_ip = IPAddress first_ip
                    last_ip = IPAddress last_ip
                    range = CpRange.new obj_name,first_ip,last_ip
                    range.raw = obj_raw
                    @objects.push range

                when "group"
                    #groups_raw.push obj_raw
                    group = CpGroup.new obj_name
                    group.raw = obj_raw
                    @objects.push group
                else
                    object = CpObject.new obj_name
                    object.raw = obj_raw
                    @objects.push object
                end
        end

        groups.each do |group|
            #pp "========== #{group.name} ==========="
            elements_names = group.raw.find_all{|l| l.match(/:Name \(.*?\)/)}
            elements_names.each do |el_name|
                    el_name = el_name.match(/\((.*?)\)/i).captures.first
                    #pp el_name
                    obj = @objects.find{|n| n.name == el_name}

                    if obj.nil?
                        group.unknown.push el_name
                        #pp "U: #{group.name} - #{el_name}"
                        #pp node_name
                    else
                        group.original.push obj
                        if obj.class.name == "CpGroup"
                            #pp "G: #{group.name} - #{el_name}"
                            group.unknown.push el_name
                        else
                            group.add obj
                        end

                    end

            end
        end

        groups.each do |group|
            if group.unknown.size != 0
                group.elements += solve_group group
            end
            group.elements.uniq!
        end
    end

    def colorize subnets, color
        objects_colored = 0
        @objects.each do |obj|
            if obj.class.name.match(/CpHost|CpNetwork|CpGroup|CpRange/)
                subnets.each do |subnet|
                    cp_network = CpNetwork.new "cp_network", subnet
                    if cp_network.include? obj
                        obj.color = color
                        objects_colored += 1
                        break
                    end
                end
            end
        end
        return objects_colored
    end

    def find_duplicates 
        dup_objects = Array.new

        @objects.each do |prim_obj|
            duplicates = @objects.find_all{|obj| prim_obj.ip_equal? obj}
            if duplicates.size > 1
                dup_objects.push duplicates.sort
            end
        end

        return dup_objects.uniq
    end
end