require_relative "../helpers.rb"
require_relative "CpPolicyEntry.rb"

class CpPolicyRule < CpPolicyEntry
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

    def name=value
        @name = value
        @raw.find{|l| l.match(/:name/)}.gsub!(/\(.*?\)/,"(#{@name})")
        return true
    end

    def name
        return @name
    end

    def comment=value
        @comment = value
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