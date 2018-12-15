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
for_deletion = Array.new
package_handler.objects_handler.objects.each do |object|
    if $unused_objects.include? object.name
        for_deletion.push object
    end
end

ap for_deletion.size






#Remove Duplicates from Policy

#delete_duplicates duplicated_groups, package_handler

#package_handler.colorize

#package_handler.export_policy "perimeter_custom_remDup.pol"
#package_handler.export_objects "objects_5_0_perimeter_custom_remDup.C"
