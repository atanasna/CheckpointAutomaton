require_relative "../helpers.rb"
require_relative "CpPolicyNatRule.rb"

class CpPolicyHandler
    include ParserHelpers
    attr_accessor :entries
    attr_reader :raw

    def initialize raw
        @entries = Array.new
        @raw = raw        

        load
    end

    # Accessors
        def rules
            return @entries.find_all{|entry| entry.class.name == "CpPolicyRule"}
        end
        
        def nat_rules
            return @entries.find_all{|entry| entry.class.name == "CpPolicyNatRule"}
        end

        def titles
            return @entries.find_all{|entry| entry.class.name == "CpPolicyTitle"}
        end

        def entries_by_vs vs_name
            entries = Array.new
            @entries.each do |entry|
                if entry.class.name == "CpPolicyRule"
                    #pp "#{entry.position} : #{entry.installed} - #{entry.installed.include?(vs_name)}"
                    if entry.installed.include?(vs_name) || entry.installed.include?("Any")
                        entries.push entry
                    end
                else
                    entries.push entry
                end
            end
            return entries
        end

    # Modifiers
        def delete_rule rule_index
            rule = rules.find{|rule| rule.index == rule_index}
            if not rule.nil?
                @entries.delete(rule)
                return true
            end
            return false
        end
        
        def reindex_entries
            rule_index = 1
            nat_index = 1
            position = 0

            @entries.each do |entry|
                case entry.class.name
                when "CpPolicyRule"
                    entry.index = rule_index
                    rule_index += 1
                when "CpPolicyNatRule"
                    entry.index = nat_index
                    nat_index += 1
                end
                entry.position = position
            end
        end

        def replace_object_in_rules(depricated, replacement)
            policy_changed = false

            all_rules = nat_rules + rules
            #print "#{depricated} : #{replacement}  | "
            all_rules.each do |rule|

                contains = false
                #print "#{rule.sources.size}:#{rule.destinations.size}"
                if rule.sources.include? depricated
                    rule.sources.delete depricated
                    rule.sources.push replacement
                    rule.sources.uniq!
                    contains = true
                    #print "s"
                end
                if rule.destinations.include? depricated
                    rule.destinations.delete depricated
                    rule.destinations.push replacement
                    rule.destinations.uniq!
                    contains = true
                    #print "d"
                end
                if rule.class.name == "CpPolicyNatRule"
                    #print "#{rule.sources_translated.size}:#{rule.destinations_translated.size}"
                    if rule.sources_translated.include? depricated
                        rule.sources_translated.delete depricated
                        rule.sources_translated.push replacement
                        rule.sources_translated.uniq!
                        contains = true
                        #print "s*"
                    end
                    if rule.destinations_translated.include? depricated
                        rule.destinations_translated.delete depricated
                        rule.destinations_translated.push replacement
                        rule.destinations_translated.uniq!
                        contains = true
                        #print "d*"
                    end
                end
                if contains
                    policy_changed = true
                    rule.raw.each do |l|
                        l.gsub!(/^\t{5}:Name \(#{depricated.name}\)/,"\t\t\t\t\t:Name (#{replacement.name})")
                    end
                end
            end

            return policy_changed
        end
        
    # Helpers
        def load
            fw_policy = open_tag @raw, "fw_policies"
            raw_rules = open_tag fw_policy.first, "rule"
            raw_nat_rules = open_tag fw_policy.first, "rule_adtr"

            rule_index = 1
            nat_index = 1
            position = 0

            raw_rules.each do |raw_rule|
                if raw_rule.any? {|line|  /security_rule/ =~ line}
                    entry = CpPolicyRule.new(raw_rule, position, rule_index)
                    #@rules.push entry
                    rule_index += 1
                else
                    entry = CpPolicyTitle.new(raw_rule, position)
                    #@titles.push entry
                end
                @entries.push entry
                position += 1
            end

            raw_nat_rules.each do |raw_nat_rule|
                if raw_nat_rule.any? {|line|  /address_translation_rule/ =~ line}
                    entry = CpPolicyNatRule.new(raw_nat_rule, position, nat_index)
                    #@rules.push entry
                    nat_index += 1
                end
                @entries.push entry
                position += 1
            end
        end

        def generate_raw 
            fw_policy_start_index = @raw.index(@raw.find{ |l| l[/\t:fw_policies \(/]}) + 20
            fw_policy_end_index = @raw.index(@raw.find{ |l| l[/\t:slp_policies \(/]})

            start_new_raw = @raw.slice 0,fw_policy_start_index
            end_new_raw = @raw.slice fw_policy_end_index-2, @raw.count-1

            new_entries = Array.new
            @entries.each do |entry|

                #if entry.class.name == "CpPolicyNatRule"
                #    new_entries.push "\t\t:rule_adtr ("
                #else
                #    new_entries.push "\t\t:rule ("
                #end
                
                new_entries += entry.raw
                new_entries.push "\t\t)"
            end

            return start_new_raw + new_entries + end_new_raw
        end

        def to_file filename
            File.open(filename, "w+") do |f|
                @raw.each { |element| f.puts(element) }
            end
        end

        def reindex_entries
            rule_index = 1
            nat_index = 1
            position = 0

            @entries.each do |entry|
                case entry.class.name
                when "CpPolicyRule"
                    entry.index = rule_index
                    rule_index += 1
                when "CpPolicyNatRule"
                    entry.index = nat_index
                    nat_index += 1
                end
                entry.position = position
            end
        end

    # Class Methods
        def self.from_file policy_file
            policy_file = File.read(policy_file)
            raw = policy_file.split(/\n+/)
            return CpPolicyHandler.new raw
        end
    
end