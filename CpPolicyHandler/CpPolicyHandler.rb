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
    
    # Helpers
        def filter_entries_by_vs vs_name
            entries = Array.new
            @entries.each do |entry|
                if entry.class.name == "PolicyRule"
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

        def to_file filename
            File.open(filename, "w+") do |f|
                @raw.each { |element| f.puts(element) }
            end
        end

        def generate_raw 
            fw_policy_start_index = @raw.index(@raw.find{ |l| l[/\t:fw_policies \(/]}) + 20
            fw_policy_end_index = @raw.index(@raw.find{ |l| l[/\t:slp_policies \(/]})

            start_new_raw = @raw.slice 0,fw_policy_start_index
            end_new_raw = @raw.slice fw_policy_end_index-2, @raw.count-1

            new_entries = Array.new
            @entries.each do |entry|

                if entry.class.name == "CpPolicyNatRule" 
                    new_entries.push "\t\t:rule_adtr ("
                else
                    new_entries.push "\t\t:rule ("
                end
                
                new_entries += entry.raw
                new_entries.push "\t\t)"
            end

            return start_new_raw + new_entries + end_new_raw
        end

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

    # Class Methods
        def self.from_file policy_file
            policy_file = File.read(policy_file)
            raw = policy_file.split(/\n+/)
            return CpPolicyHandler.new raw
        end
    
end