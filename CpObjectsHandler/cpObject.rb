class CpObject
    attr_accessor :name

    def initialize name
        @name = name
    end

    # for sorting
    def <=> (cp_object)
        @name <=> cp_object.name
    end
end