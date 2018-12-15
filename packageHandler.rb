require_relative "CpPolicyHandler/CpPolicyEntry.rb"
require_relative "CpPolicyHandler/CpPolicyRule.rb"
require_relative "CpPolicyHandler/CpPolicyTitle.rb"
require_relative "CpPolicyHandler/CpPolicyHandler.rb"
require_relative "CpObjectsHandler/CpObjectsHandler.rb"
require_relative "../topographer/graph/graph.rb"
require "ipaddress"
require "awesome_print"

class PackageHandler
    attr_accessor :objects_handler, :policy_handler

    def initialize objects_filename=nil, policy_filename=nil
        @objects_handler = nil
        @policy_handler = nil
        # Load Objects
            load_objects_handler objects_filename
        # Load Policy
            load_policy_handler policy_filename
    end

    def load_objects_handler objects_filename
        if objects_filename.nil?
            return
        end
        start_time = Time.now
        print "Loading Objects(~10s) . . . "
        @objects_handler = CpObjectsHandler.new objects_filename
        puts "OK! - #{Time.now - start_time}s"
    end

    def load_policy_handler policy_filename
        if policy_filename.nil?
            return
        end
        start_time = Time.now
        print "Loading Policy(~40s) . . . "

        @policy_handler = CpPolicyHandler.from_file policy_filename

        @policy_handler.rules.each do |rule|
            sources = Array.new
            destinations = Array.new

            all = rule.sources + rule.destinations
        
            all.each do |target|
                if rule.sources.include? target
                    if target=="Any" then target = "All_Internet" end
                    sources.push @objects_handler.objects.find{|obj| obj.name==target}
                end
                if rule.destinations.include? target
                    if target=="Any" then target = "All_Internet" end
                    destinations.push @objects_handler.objects.find{|obj| obj.name==target}
                end
            end

            rule.sources = sources
            rule.destinations = destinations
        end

        @policy_handler.nat_rules.each do |nat_rule|
            sources = Array.new
            destinations = Array.new
            sources_translated = Array.new
            destinations_translated = Array.new
            all = nat_rule.sources + nat_rule.destinations + nat_rule.sources_translated + nat_rule.destinations_translated
            

            all.each do |target|
                if nat_rule.sources.include? target
                    if target=="Any" then target = "All_Internet" end
                    sources.push @objects_handler.objects.find{|obj| obj.name==target}
                end
                if nat_rule.destinations.include? target
                    if target=="Any" then target = "All_Internet" end
                    destinations.push @objects_handler.objects.find{|obj| obj.name==target}
                end
                if nat_rule.sources.include? target
                    if target=="Any" then target = "All_Internet" end
                    sources_translated.push @objects_handler.objects.find{|obj| obj.name==target}
                end
                if nat_rule.sources.include? target
                    if target=="Any" then target = "All_Internet" end
                    sources_translated.push @objects_handler.objects.find{|obj| obj.name==target}
                end
            end

            nat_rule.sources = sources
            nat_rule.destinations = destinations
            nat_rule.sources_translated = sources_translated
            nat_rule.destinations_translated = destinations_translated
        end
        puts "------\n----"
        ap policy_handler.nat_rules[10]
        puts "OK! - #{Time.now - start_time}s"
    end

    def find_rules lookups, in_src=true, in_dst=false
        rules = Array.new
        
        @policy_handler.rules.each do |rule|
            lookups.each do |lookup|
                if in_src
                    if rule.sources.find{|source| source.include? lookup}
                        rules.push rule
                    end
                end
                if in_dst
                    if rule.destinations.find{|destination| destination.include? lookup}
                        rules.push rule
                    end
                end
            end
        end

        return rules.uniq.sort
    end

    def find_unused
        unused_objects = Array.new
        @objects_handler.objects.each do |object|

        end
    end
    # Changers
        def colorize
            puts "------>> Colorizing(~5s)"
            print "coloring all . . . "
            puts "OK! - #{@objects_handler.colorize [IPAddress("0.0.0.0/0")], "firebrick"} objects colored in firebrick"

            print "coloring core . . . "
            puts "OK! - #{@objects_handler.colorize $dc_subnets, "olive"} objects colored in olive"

            print "coloring dmz . . . "
            puts "OK! - #{@objects_handler.colorize $dmz_subnets, "orange"} objects colored in orange"

            print "coloring office . . . "
            puts "OK! - #{@objects_handler.colorize $office_subnets, "gold"} objects colored in gold"

            print "coloring roadWarriors . . . "
            puts "OK! - #{@objects_handler.colorize $rw_subnets, "dark gold"} objects colored in dark gold"
        end

        def remove_duplicates
            start_time = Time.now
            puts "------>> Removing duplicate objects(~60s)"
            deleted_cnt = 0
            print "Looking for duplicates(~30s) . . . "
            duplicated_groups = @objects_handler.find_duplicates    
            puts "OK! - #{Time.now - start_time}s"

            print "Removing duplicate objects(~30s) . . . "
            for_deletion = Array.new
            duplicated_groups.each do |dup_group|
                dup_group.each do |dup_object|
                    if dup_object == dup_group.first
                        next
                    end
                    for_deletion.push dup_object

                    #Removing Duplicates from Policy
                        @policy_handler.rules.each do |rule|
                            contains = false
                            if rule.sources.include? dup_object
                                rule.sources.delete dup_object
                                rule.sources.push dup_group.first
                                rule.sources.uniq!
                                contains = true
                            end
                            if rule.destinations.include? dup_object
                                rule.destinations.delete dup_object
                                rule.destinations.push dup_group.first
                                rule.destinations.uniq!
                                contains = true
                            end
                            if contains
                                rule.raw.each do |l|
                                    l.gsub!(/^\t{5}:Name \(#{dup_object.name}\)/,"\t\t\t\t\t:Name (#{dup_group.first.name})")
                                end
                            end
                        end

                    #Removing Duplicates from Objects
                        @objects_handler.groups.each do |group|
                            if group.include? dup_object
                                group.remove dup_object
                                group.add dup_group.first

                                group.raw.each do |l|
                                    l.gsub!(/^\t{4}:Name \(#{dup_object.name}\)/,"\t\t\t\t:Name (#{dup_group.first.name})")
                                end
                            end
                        end
                end
            end         
            for_deletion.each do |obj|
                @objects_handler.objects.delete(obj)
                deleted_cnt += 1
            end
            puts "OK! - #{deleted_cnt} objects deleted"  
        end

        def remove_unused unused_objects_names
            start_time = Time.now
            puts "------>> Removing unused objects(~1s)"
            print "Removing unused objects(~1s) . . . "
            deleted_cnt = 0
            for_deletion = Array.new

            @objects_handler.objects.each do |object|
                if unused_objects_names.include? object.name
                    for_deletion.push object
                end
            end

            for_deletion.each do |obj|
                @objects_handler.objects.delete(obj)
                deleted_cnt += 1
            end

            puts "OK! - #{deleted_cnt} objects deleted "
        end


    # Exports
        def export_policy filename
            print "Writing Policy to file . . . "
            File.open(filename, "w+") do |f|
                @policy_handler.generate_raw.each { |element| f.puts(element) }
            end
            puts "done" #{filename}"
        end

        def export_objects filename
            print "Writing Objects to file . . . "
            File.open(filename, "w+") do |f|
                @objects_handler.generate_raw.each { |element| f.puts(element) }
            end
            puts "done" #{filename}"
        end
    # Statistics
        def print_policy_stats
            puts "------>> Policy Statistics"
            puts "Entries: #{@policy_handler.entries.count}"
            puts "Titles: #{@policy_handler.titles.count}"
            puts "Rules: #{@policy_handler.rules.count}"
            puts "NAT Rules: #{@policy_handler.nat_rules.count}"
            puts "Active R: #{@policy_handler.rules.find_all{|rule| rule.disabled==false}.count}"
            puts "Disabled R: #{@policy_handler.rules.find_all{|rule| rule.disabled==true}.count}"
        end
        
        def print_objects_stats
            puts "------>> Objects Statistics "
            puts "Objects: #{@objects_handler.objects.size}"
            puts "Hosts: #{@objects_handler.hosts.size}"
            puts "Networks: #{@objects_handler.networks.size}"
            puts "Ranges: #{@objects_handler.ranges.size}"
            puts "Groups: #{@objects_handler.groups.size}"
        end

        def print_policy_stat_by_fw fw_name
            rulebase = @policy_handler.filter_entries_by_vs(fw_name).find_all{|rule| rule.class.name=="PolicyRule"}
            print "#{fw_name} rules a/d/s/t: "
            print "#{rulebase.find_all{|rule| rule.disabled==false}.count}/"
            print "#{rulebase.find_all{|rule| rule.disabled==true}.count}/"
            print "#{rulebase.find_all{|rule| rule.disabled==false}.find_all{|rule| rule.installed.count>1}.count}/"
            puts "#{rulebase.count}"
        end

        def print_color_stats
            puts "------>> Coloring Statistics"
            ap "Firebrick-Hosts: #{@objects_handler.objects.find_all{|obj| obj.color=="firebrick" and obj.class.name=="CpHost"}.size}"
            ap "Firebrick-Networks: #{@objects_handler.objects.find_all{|obj| obj.color=="firebrick" and obj.class.name=="CpNetwork"}.size}"
            ap "Firebrick-Ranges: #{@objects_handler.objects.find_all{|obj| obj.color=="firebrick" and obj.class.name=="CpRange"}.size}"
            ap "Firebrick-Groups: #{@objects_handler.objects.find_all{|obj| obj.color=="firebrick" and obj.class.name=="CpGroup"}.size}"
            ap "--"
            ap "Olive-Hosts: #{@objects_handler.objects.find_all{|obj| obj.color=="\"olive drab\"" and obj.class.name=="CpHost"}.size}"
            ap "Olive-Networks: #{@objects_handler.objects.find_all{|obj| obj.color=="\"olive drab\"" and obj.class.name=="CpNetwork"}.size}"
            ap "Olive-Ranges: #{@objects_handler.objects.find_all{|obj| obj.color=="\"olive drab\"" and obj.class.name=="CpRange"}.size}"
            ap "Olive-Groups: #{@objects_handler.objects.find_all{|obj| obj.color=="\"olive drab\"" and obj.class.name=="CpGroup"}.size}"
            ap "--"
            ap "Orange-Hosts: #{@objects_handler.objects.find_all{|obj| obj.color=="orange" and obj.class.name=="CpHost"}.size}"
            ap "Orange-Networks: #{@objects_handler.objects.find_all{|obj| obj.color=="orange" and obj.class.name=="CpNetwork"}.size}"
            ap "Orange-Ranges: #{@objects_handler.objects.find_all{|obj| obj.color=="orange" and obj.class.name=="CpRange"}.size}"
            ap "Orange-Groups: #{@objects_handler.objects.find_all{|obj| obj.color=="orange" and obj.class.name=="CpGroup"}.size}"
            ap "--"
            ap "Gold-Hosts: #{@objects_handler.objects.find_all{|obj| obj.color=="gold" and obj.class.name=="CpHost"}.size}"
            ap "Gold-Networks: #{@objects_handler.objects.find_all{|obj| obj.color=="gold" and obj.class.name=="CpNetwork"}.size}"
            ap "Gold-Ranges: #{@objects_handler.objects.find_all{|obj| obj.color=="gold" and obj.class.name=="CpRange"}.size}"
            ap "Gold-Groups: #{@objects_handler.objects.find_all{|obj| obj.color=="gold" and obj.class.name=="CpGroup"}.size}"
        end
end

