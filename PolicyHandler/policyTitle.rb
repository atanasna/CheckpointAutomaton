require_relative "../helpers.rb"
require_relative "policyEntry.rb"

class PolicyTitle < PolicyEntry
    def initialize raw, position
        super(raw, position)
        @name = parse_tag "header_text"
    end
end