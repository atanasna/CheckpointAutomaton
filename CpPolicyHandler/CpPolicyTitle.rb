require_relative "../helpers.rb"
require_relative "CpPolicyEntry.rb"

class CpPolicyTitle < CpPolicyEntry
    def initialize raw, position
        super(raw, position)
        @name = parse_tag "header_text"
    end
end