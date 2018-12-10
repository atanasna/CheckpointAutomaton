require_relative "../helpers.rb"
require_relative "policyEntry.rb"

class PolicyRule < PolicyEntry
    attr_accessor :index, :type, :installed, :sources, :destinations, :disabled

    def initialize raw, position, index 
        super(raw, position)
        @index = index
        @name = parse_tag "name"
        @disabled = parse_tag "disabled" 
        if @disabled=="false" then @disabled=false end
        if @disabled=="true" then @disabled=true end

        @sources = parse_tag "src"
        @destinations = parse_tag "dst"
        @services = parse_tag "services"
        @installed = parse_tag "install"
        @comment = parse_tag "comments"

        
    end

    def comment=val
        @comment = val
        @raw.find{|l| l.match(/comment/)}.gsub!(/\(.*?\)/,"(#{@comment})")
        return true
    end

    def comment
        return @comment
    end

    def print
        super
        pp "@index: #{@index}"
        pp "@disabled: #{@disabled}"
        pp "@src: #{@src}"
        pp "@dst: #{@dst}"
        pp "@services: #{@services}"
        pp "@installed: #{@installed}"
        pp "@comment: #{@comment}"
    end
end