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

    def initialize
        # Start
            ap "Start"
            start_time = Time.now
            time_now = Time.now

        # Load Objects
            print "Loading Objects . . . "
            @objects_handler = CpObjectsHandler.new "objects_5_0_core.c"
            puts "done: #{Time.now - time_now}s"; time_now = Time.now

        # Load policy
            print "Loading Policy . . . "
            @policy_handler = CpPolicyHandler.from_file "standard-clone.pol"

            @policy_handler.rules.each do |rule|
                sources = Array.new
                destinations = Array.new

                rule.sources.each do |source|
                    sources.push @objects_handler.objects.find{|obj| obj.name==source}
                end
                
                rule.destinations.each do |source|
                    destinations.push @objects_handler.objects.find{|obj| obj.name==source}
                end

                rule.sources = sources
                rule.destinations = destinations
            end
            puts "done: #{Time.now - time_now}s"; time_now = Time.now
    end

    def find_rules networks, in_src=true, in_dst=false
        rules = Array.new

        networks.each do |network|
            @policy_handler.rules.each do |rule|
                if in_src
                    if rule.sources.find{|source| source.include? network}
                        rules.push rule
                    end
                end
                if in_dst
                    if rule.destinations.find{|destination| destination.include? network}
                        rules.push rule
                    end
                end
            end
        end

        return rules.uniq.sort
    end

    def generate_statistics
        ap "-------------- CpObjectsHandler ----------------"
        ap "Objects: #{@objects_handler.objects.size}"
        ap "Hosts: #{@objects_handler.hosts.size}"
        ap "Networks: #{@objects_handler.nets.size}"
        ap "Ranges: #{@objects_handler.ranges.size}"
        ap "Groups: #{@objects_handler.groups.size}"
        ap "--------------- CpPolicyHandler ----------------"
        ap "Entries: #{@policy_handler.entries.count}"
        ap "Rules: #{@policy_handler.rules.count}"
        ap "Active R: #{@policy_handler.rules.find_all{|rule| rule.disabled==false}.count}"
        ap "Disabled R: #{@policy_handler.rules.find_all{|rule| rule.disabled==true}.count}"
        ap "---------------------------------------"
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

