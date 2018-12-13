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

    def initialize objects_filename, policy_filename
        @objects_handler = nil
        @policy_handler = nil
        # Load Objects
            load_objects_handler objects_filename
        # Load Policy
            load_policy_handler policy_filename
    end

    def load_objects_handler objects_filename
        start_time = Time.now
        print "Loading Objects(~9s) . . . "
        @objects_handler = CpObjectsHandler.new objects_filename
        puts "loaded: #{Time.now - start_time}s"
    end

    def load_policy_handler policy_filename
        start_time = Time.now
        print "Loading Policy(~40s) . . . "

        @policy_handler = CpPolicyHandler.from_file policy_filename

        @policy_handler.rules.each do |rule|
            sources = Array.new
            destinations = Array.new
            anyObject = CpNetwork.new "Any",IPAddress("0.0.0.0/24")

            rule.sources.each do |source|
                if source=="Any"
                    sources.push anyObject
                else
                    sources.push @objects_handler.objects.find{|obj| obj.name==source}
                end
            end
            
            rule.destinations.each do |destination|
                if destination=="Any"
                    destinations.push anyObject
                else
                    destinations.push @objects_handler.objects.find{|obj| obj.name==destination}
                end
            end

            rule.sources = sources
            rule.destinations = destinations
        end
        puts "loaded: #{Time.now - start_time}s"
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

    def stats_policy
        puts "--------------- Policy Statistics ----------------"
        puts "Entries: #{@policy_handler.entries.count}"
        puts "Titles: #{@policy_handler.titles.count}"
        puts "Rules: #{@policy_handler.rules.count}"
        puts "Active R: #{@policy_handler.rules.find_all{|rule| rule.disabled==false}.count}"
        puts "Disabled R: #{@policy_handler.rules.find_all{|rule| rule.disabled==true}.count}"
        puts "--------------------------------------------------"
    end
    
    def stats_objects
        puts "-------------- Objects Statistics ----------------"
        puts "Objects: #{@objects_handler.objects.size}"
        puts "Hosts: #{@objects_handler.hosts.size}"
        puts "Networks: #{@objects_handler.networks.size}"
        puts "Ranges: #{@objects_handler.ranges.size}"
        puts "Groups: #{@objects_handler.groups.size}"
        puts "--------------------------------------------------"
    end

    def print_fw_policy_stat fw_name
        rulebase = @policy_handler.filter_entries_by_vs(fw_name).find_all{|rule| rule.class.name=="PolicyRule"}
        print "#{fw_name} rules a/d/s/t: "
        print "#{rulebase.find_all{|rule| rule.disabled==false}.count}/"
        print "#{rulebase.find_all{|rule| rule.disabled==true}.count}/"
        print "#{rulebase.find_all{|rule| rule.disabled==false}.find_all{|rule| rule.installed.count>1}.count}/"
        puts "#{rulebase.count}"
    end

    
end

