require_relative "../helpers.rb"
require_relative "CpPolicyEntry.rb"

class CpPolicyNatRule < CpPolicyEntry
    attr_accessor :index, :type, :installed, :sources, :sources_translated, :destinations, :destinations_translated, :disabled

    def initialize raw, position, index 
        super(raw, position)
        @index = index
        @name = parse_tag "name"
        @disabled = parse_tag "disabled"
        if @disabled=="false" then @disabled=false end
        if @disabled=="true" then @disabled=true end

        @sources = parse_tag "src_adtr"
        @destinations = parse_tag "dst_adtr"
        @services = parse_tag "services_adtr"

        @sources_translated = parse_tag "src_adtr_translated"
        @destinations_translated = parse_tag "dst_adtr_translated"
        @services_translated = parse_tag "services_adtr_translated"

        @installed = parse_tag "install"
        @comment = parse_tag "comments"
    end

end