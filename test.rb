require_relative "helpers.rb"
require_relative "CpObjectsHandler/cpHost.rb"
require_relative "CpObjectsHandler/cpGroup.rb"
require_relative "CpObjectsHandler/cpNetwork.rb"
require_relative "CpObjectsHandler/cpRange.rb"
require_relative "CpObjectsHandler/cpObjectsHandler.rb"
require_relative "packageHandler.rb"
require_relative "../topographer/topographer.rb"
require_relative "manualMapping.rb"
require "ipaddress"
require "awesome_print"

#package_handler = PackageHandler.new "objects_5_0_perimeter_original.c"#, "perimeter_original.pol"
#package_handler = PackageHandler.new "objects_5_0_perimeter_c_duplicates.c"#, "perimeter_original.pol"
package_handler = PackageHandler.new "objects_5_0_perimeter_c_unused.c"#, "perimeter_original.pol"

groups = package_handler.objects_handler.groups
groups.each_with_index do |g,i|
    g.elements.each do |el|
        if el.class == CpGroup
            ap "#{g.name}/#{i} - #{el.name} - #{el.class.name}"
        end
    end
end

ap ""
ap ""

group = package_handler.objects_handler.groups[1]
group.expand.each do |el|
    ap "#{el.name} - #{el.class.name}"
end