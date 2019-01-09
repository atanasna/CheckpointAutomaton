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

    # loaders
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

            all_rules = @policy_handler.rules + @policy_handler.nat_rules
            all_rules.each do |rule|
                sources = Array.new
                destinations = Array.new
                sources_translated = Array.new
                destinations_translated = Array.new
                all = Array.new

                if rule.class.name == "CpPolicyRule"
                    all = rule.sources + rule.destinations
                end
                if rule.class.name == "CpPolicyNatRule"
                    all = rule.sources + rule.destinations + rule.sources_translated + rule.destinations_translated
                end
                
                all.each do |target|
                    if rule.sources.include? target
                        if target=="Any" then target = "All_Internet" end
                        sources.push @objects_handler.objects.find{|obj| obj.name==target}
                    end
                    if rule.destinations.include? target
                        if target=="Any" then target = "All_Internet" end
                        destinations.push @objects_handler.objects.find{|obj| obj.name==target}
                    end
                    if rule.class.name == "CpPolicyNatRule"
                        if rule.sources_translated.include? target
                            if target=="Any" then target = "All_Internet" end
                            sources_translated.push @objects_handler.objects.find{|obj| obj.name==target}
                        end
                        if rule.destinations_translated.include? target
                            if target=="Any" then target = "All_Internet" end
                            destinations_translated.push @objects_handler.objects.find{|obj| obj.name==target}
                        end
                    end
                end

                rule.sources = sources
                rule.destinations = destinations
                if rule.class.name == "CpPolicyNatRule"
                    rule.sources_translated = sources_translated
                    rule.destinations_translated = destinations_translated
                end
            end
            puts "OK! - #{Time.now - start_time}s"
        end

    # helpers
    def find_unused_objects_in_policy
        unused_objects = Array.new
        @objects_handler.objects.each do |object|
            used = false
            #checking if used in policy
            @policy_handler.entries.each do |entry|
                if entry.respond_to?('sources') and entry.sources.include? object
                    used = true
                    break
                end
                if entry.respond_to?('destinations') and entry.destinations.include? object
                    used = true
                    break
                end
                if entry.respond_to?('sources_translated') and entry.sources_translated.include? object
                    used = true
                    break
                end
                if entry.respond_to?('destinations_translated') and entry.destinations_translated.include? object
                    used = true
                    break
                end
            end

            if not used
                unused_objects.push object
            end
        end     

        return unused_objects
    end

    # Modifiers
        #independent
        def colorize
            puts "------>> Colorizing(~5s)"
            print "coloring all . . . "
            @objects_handler.colorize [IPAddress("0.0.0.0/0")], "firebrick"
            puts "OK! - Firebrick"

            print "coloring core . . . "
            @objects_handler.colorize $dc_subnets, "olive"
            puts "OK! - Olive"

            print "coloring dmz . . . "
            @objects_handler.colorize $dmz_subnets, "orange"
            puts "OK! - Orange"

            print "coloring office . . . "
            @objects_handler.colorize $office_subnets, "gold"
            puts "OK! - Gold"

            print "coloring roadWarriors . . . "
            @objects_handler.colorize $rw_subnets, "dark gold"
            puts "OK! - Dark gold"
        end
        #independent
        def remove_duplicates
            start_time = Time.now
            puts "------>> Removing duplicate objects(~60s)"
            print "Looking for duplicates(~30s) . . . "
            deleted_cnt = 0
            duplicated_groups = @objects_handler.find_duplicates    

            names = Array.new
            puts "OK! - #{Time.now - start_time}s"

            print "Removing duplicate objects(~30s) . . . "
            for_deletion = Array.new
            duplicated_groups.each do |dup_group|
                dup_group.each do |dup_object|
                    if dup_object == dup_group.first
                        next
                    end
                    for_deletion.push dup_object

                    #Removing Duplicates from Policy Rules
                        all_rules = @policy_handler.nat_rules + @policy_handler.rules
                        all_rules.each do |rule|
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
                            if rule.class.name == "CpPolicyNatRule"
                                if rule.sources_translated.include? dup_object
                                    rule.sources_translated.delete dup_object
                                    rule.sources_translated.push dup_group.first
                                    rule.sources_translated.uniq!
                                    contains = true
                                end
                                if rule.destinations_translated.include? dup_object
                                    rule.destinations_translated.delete dup_object
                                    rule.destinations_translated.push dup_group.first
                                    rule.destinations_translated.uniq!
                                    contains = true
                                end
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

        #needs tufin
        def remove_unused
            start_time = Time.now
            deleted_cnt = 0
            puts "------>> Removing unused objects(~1s)"
            puts "Looking for unused objects(~0s) . . . OK! - tufin provided"

            #unused_objects = find_unused
            #puts
            #puts unused_objects.size
            #unused_objects.each{|o| ap o.name}
            #
            print "Removing unused objects(~1s) . . . "
            $unused_objects.each do |unused_object_name|
                unused_object = @objects_handler.objects.find{|o| o.name == unused_object_name}
                if not unused_object.nil?
                    @objects_handler.objects.delete(unused_object)
                    deleted_cnt +=1
                end
            end
            puts "OK! - #{deleted_cnt} objects deleted "
        end

        #needs tufin
        def remove_shadowed_rules
            start_time = Time.now
            deleted_cnt = 0
            puts "------>> Removing shadowed rules (~1s)"
            puts "Looking for shadowed rules(~0s) . . . OK! - tufin provided"
            
            print "Removing shadowed rules(~1s) . . . "
            $shadowed_rules.each do |rule_i|
                if @policy_handler.delete_rule rule_i
                    deleted_cnt +=1
                end
            end
            puts "OK! - #{deleted_cnt} objects deleted "
        end

    # Exporters
        def export_policy filename
            print "Writing Policy to file . . . "
            File.open(filename, "w+") do |f|
                @policy_handler.generate_raw.each { |element| f.puts(element) }
            end
            puts "OK! - #{filename}"
        end

        def export_objects filename
            print "Writing Objects to file . . . "
            File.open(filename, "w+") do |f|
                @objects_handler.generate_raw.each { |element| f.puts(element) }
            end
            puts "OK! - #{filename}"
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
            ap "Core(Olive): #{@objects_handler.objects.find_all{|obj| obj.color=="\"olive drab\""}.size}"
            ap "DMZ(Orange): #{@objects_handler.objects.find_all{|obj| obj.color=="orange"}.size}"
            ap "Office(Gold): #{@objects_handler.objects.find_all{|obj| obj.color=="gold"}.size}"
            ap "RemoteVPN(Dark Gold): #{@objects_handler.objects.find_all{|obj| obj.color=="gold3"}.size}"
            ap "EverythingElse(Firebrick): #{@objects_handler.objects.find_all{|obj| obj.color=="firebrick"}.size}"
        end
end

