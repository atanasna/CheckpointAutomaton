require_relative "../helpers.rb"

class PolicyHandler
    include ParserHelpers
    attr_accessor :entries, :rules, :titles
    attr_reader :raw

    def initialize raw
        @entries = Array.new
        @rules = Array.new
        @titles = Array.new
        @raw = raw        

        load
    end

    def load
        fw_policy = open_tag_policy @raw, "fw_policies"
        raw_rules = open_tag_policy fw_policy.first, "rule"

        index = 1
        position = 0

        raw_rules.each do |raw_rule|
            if raw_rule.any? {|line|  /security_rule/ =~ line}
                entry = PolicyRule.new(raw_rule, position, index)
                @rules.push entry
                index += 1
            else
                entry = PolicyTitle.new(raw_rule, position)
                @titles.push entry
            end
            @entries.push entry
            position += 1
        end
    end

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


    def self.generate_raw original_raw, entries
        fw_policy_start_index = original_raw.index(original_raw.find{ |l| l[/\t:fw_policies \(/]}) + 20
        fw_policy_end_index = original_raw.index(original_raw.find{ |l| l[/\t:slp_policies \(/]})

        start_new_raw = original_raw.slice 0,fw_policy_start_index
        end_new_raw = original_raw.slice fw_policy_end_index-2, original_raw.count-1

        new_entries = Array.new
        entries.each do |entry|
            new_entries.push "\t\t:rule ("
            new_entries += entry.raw
            new_entries.push "\t\t)"
        end

        return start_new_raw + new_entries + end_new_raw
    end

    def self.from_file policy_file
        policy_file = File.read(policy_file)
        raw = policy_file.split(/\n+/)
        return PolicyHandler.new raw
    end
    
end