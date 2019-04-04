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

    # modifiers
        # independent
        # changes the colours of all objects
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

        # independent
        # deletes all duplicated objects
        def remove_duplicated_objects
            start_time = Time.now

            puts "------>> Removing duplicate objects(~60s)"
            print "Looking for duplicates(~30s) . . . "
            deleted_cnt = 0
            duplicated_groups = @objects_handler.find_duplicates    

            names = Array.new
            puts "OK! - #{Time.now - start_time}s" 

            start_time = Time.now
            print "Removing duplicate objects(~30s) . . . "
            for_deletion = Array.new
            duplicated_groups.each do |dup_group|

                dup_group.each do |dup_object|
                    if dup_object == dup_group.first
                        next
                    end
                    for_deletion.push dup_object
                    #Removing Duplicates from Policy Rules
                        # THIS PART IS NOT WORKING FOR SOME REASON
                        @policy_handler.replace_object_in_rules(dup_object, dup_group.first)

                    #Removing Duplicates from Groups
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
                @objects_handler.delete_object(obj)
                deleted_cnt += 1
            end
            puts "OK! - #{Time.now - start_time}s #{deleted_cnt} objects deleted"  
        end

        # independent
        # replaces all /32 network objects with hosts
        def replace_slash32_networks
            start_time = Time.now
            puts "------>> Removing slash32 newtworks(~3s)"
            print "Looking for slash32 newtworks(~1s) . . . "
            
            #Find all /32 networks
            slash32_networks = @objects_handler.find_slash32_networks
            replacement_hosts = Array.new

            # find replacement hosts
            slash32_networks.each do |network|
                matching_host = @objects_handler.hosts.find{|host| host.address == network.address}
                if matching_host.nil?
                    namae = network.name.sub(/[Nn][Ee][Tt]/,"h")
                    address = network.address
                    prefix = network.prefix
                    replacement = CpHost.new("#{namae}", IPAddress("#{address}/#{prefix}"))
                    replacement_hosts.push replacement
                    @objects_handler.objects.push replacement
                else
                    replacement_hosts.push matching_host
                end
            end
            puts "OK! - #{Time.now - start_time}s " 
            start_time = Time.now
            print "Removing slash32 newtworks(~2s) . . . "
            
            #Remove slash32 networks
            slash32_networks.size.times do |i|

                #Replacing object in the Policy Rules
                    @policy_handler.replace_object_in_rules(slash32_networks[i], replacement_hosts[i])
                #Replacing object in Groups
                    @objects_handler.groups.each do |group|
                        if group.include? slash32_networks[i]
                            group.remove slash32_networks[i]
                            group.add replacement_hosts[i]
                            group.raw.each do |l|
                                l.gsub!(/^\t{4}:Name \(#{slash32_networks[i].name}\)/,"\t\t\t\t:Name (#{replacement_hosts[i].name})")
                            end
                        end
                    end      
            end

            deleted_cnt = 0
            slash32_networks.each do |network|
                @objects_handler.delete_object(network)
                deleted_cnt += 1
            end
            puts "OK! - #{Time.now - start_time}s #{deleted_cnt} objects deleted"  

            #print slash32_networks
            #puts "#{slash32_networks.size} - #{replacement_hosts.size}"
            #slash32_networks.each_index do |i|
            #    print "#{slash32_networks[i].name} - #{slash32_networks[i].address}/#{slash32_networks[i].prefix}".ljust(50)
            #    print " | "
            #    puts "#{replacement_hosts[i].name} - #{replacement_hosts[i].address}".ljust(50)
            #end
        end

        def rename_to_fqdns
            start_time = Time.now
            cnt = 0
            host_cnt = 0
            puts "------>> Renaming Host Objects based on DNS Records(~120s)"
            print "Renaming (~120s) . . . "

            objects_handler.hosts.each do |host|
                
                if $dns_names[host.address.address]
                    old_name = host.name
                    new_name = $dns_names[host.address.address].downcase

                    if objects_handler.rename_object old_name, new_name
                        policy_handler.entries.each do |rule|
                            rule.raw.each do |line|
                                line.gsub!("\t\t\t\t\t:Name (#{old_name})","\t\t\t\t\t:Name (#{new_name})")
                                #line.gsub!("#{host.name}","#{$dns_names[host.address.address].downcase}")
                            end
                        end

                        if old_name.match(/[hH][oO][sS][tT]/)
                            host_cnt += 1
                        end
                        cnt += 1
                    end
                    ap cnt
                end
            end
            
            puts "OK! - #{Time.now - start_time}s #{cnt} hosts renamed #{host_cnt} of which have 'host' in the name"  
        end

        #depends on tufin
        def remove_unused_objects
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

        #depends on tufin
        def remove_shadowed_rules_tufin
            start_time = Time.now
            deleted_cnt = 0
            puts "------>> Removing shadowed rules (~1s)"
            puts "Looking for shadowed rules(~0s) . . . OK! - tufin provided"
            
            print "Removing shadowed rules(~1s) . . . "
            $tufin_shadowed_rules.each do |rule_id|
                if @policy_handler.delete_rule rule_id
                    deleted_cnt +=1
                end
            end
            puts "OK! - #{deleted_cnt} objects deleted "
        end

        # independent
        # deletes all disabled rules
        def remove_disabled_rules
            start_time = Time.now
            deleted_cnt = 0
            puts "------>> Removing disabled rules (~1s)"
            print "Looking for disabled rules(~1s) . . . " 
            rules_for_deletetion = Array.new
            @policy_handler.rules.each do |rule|
                if rule.disabled
                    rules_for_deletetion.push rule
                end
            end
            puts "OK! - #{Time.now - start_time}s"

            start_time = Time.now 
            print "Removing disabled rules(~1s) . . . "
            rules_for_deletetion.each do |rule|
                if @policy_handler.delete_rule rule.index
                    deleted_cnt +=1
                end
            end
            puts "OK! - #{Time.now - start_time}s - #{deleted_cnt} objects deleted"
        end

        # dependant on having "#nonZero" in the name column of the rule
        # tags all unused rules with "#zero" in the name
        def tag_unused_rules
            start_time = Time.now

            tagged_cnt = 0
            puts "------>> Tagging unused rules with #zero (~1s)"
            print "Looking for unused rules(~0s) . . . " 
            @policy_handler.rules.each do |rule|
                if rule.name.match(/#nonZero/)
                    rule.name = rule.name.sub("#nonZero","")
                else
                    rule.name = "#zero"
                    tagged_cnt += 1
                end
            end
            puts "OK! - #{Time.now - start_time}s, #{tagged_cnt}"
        end

        # dependant on having "#zero" in the name column of the rule
        # deletes all rules with "#zero" in the name
        def remove_unused_rules
            # Deletes all rules with "#zero" in the name
            start_time = Time.now
            deleted_cnt = 0
            puts "------>> Removing unused rules(tagged with #zero) (~1s)"
            print "Looking for unused rules(~0s) . . . " 
            rules_for_deletetion = Array.new
            @policy_handler.rules.each do |rule|
                if rule.name.match(/#zero/)
                    rules_for_deletetion.push rule
                end
            end
            puts "OK! - #{Time.now - start_time}s"

            start_time = Time.now 
            print "Removing unused rules(~1s) . . . "
            rules_for_deletetion.each do |rule|
                if @policy_handler.delete_rule rule.index
                    deleted_cnt +=1
                end
            end
            puts "OK! - #{Time.now - start_time}s - #{deleted_cnt} objects deleted "
        end

        #depends on tufin
        def remove_unused_rules_tufin
            # Deletes all rules with "#zero" in the name
            puts "------>> Removing unused rules (~1s)"
            puts "Looking for unused rules(~0s) . . . OK! Tufin provided" 
            start_time = Time.now
            deleted_cnt = 0
            print "Removing unused rules(~1s) . . . "
            $tufin_unused_rules.each do |rule_id|
                if @policy_handler.delete_rule rule_id
                    deleted_cnt +=1
                end
            end
            puts "OK! - #{Time.now - start_time}s - #{deleted_cnt} objects deleted "
        end

        def add_new_titles
            start_time = Time.now
            puts "------>> Adding new policy Titles (~1s)"
            print "Adding new policy Title(~1s) . . . "
            titles = Array.new
            $new_titles.each_with_index do |title, i|
                titles.push CpPolicyTitle.new(CpPolicyTitle.raw_template(title), 10000+i)
            end

            @policy_handler.entries = titles + @policy_handler.entries
            puts "OK! - #{Time.now-start_time}"
        end
    
    # exporters
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

    # statistics
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
            objects_in_groups = 0
            @objects_handler.groups.each do |g|
                objects_in_groups += g.elements.size
            end
            puts "Objects in Groups: #{objects_in_groups}"
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
            puts "Core(Olive): #{@objects_handler.objects.find_all{|obj| obj.color=="\"olive drab\""}.size}"
            puts "DMZ(Orange): #{@objects_handler.objects.find_all{|obj| obj.color=="orange"}.size}"
            puts "Office(Gold): #{@objects_handler.objects.find_all{|obj| obj.color=="gold"}.size}"
            puts "RemoteVPN(Dark Gold): #{@objects_handler.objects.find_all{|obj| obj.color=="gold3"}.size}"
            puts "EverythingElse(Firebrick): #{@objects_handler.objects.find_all{|obj| obj.color=="firebrick"}.size}"
        end
end

