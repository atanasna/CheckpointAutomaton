require_relative "helpers.rb"
require_relative "CpObjectsHandler/cpHost.rb"
require_relative "CpObjectsHandler/cpGroup.rb"
require_relative "CpObjectsHandler/cpNetwork.rb"
require_relative "CpObjectsHandler/cpRange.rb"
require_relative "CpObjectsHandler/cpObjectsHandler.rb"
require_relative "packageHandler.rb"
require_relative "../topographer/topographer.rb"
require_relative "config/localMappings.rb"
require_relative "config/tufinMappings.rb"
require "ipaddress"
require "awesome_print"

package_handler = PackageHandler.new "objects_5_0_prodCore.C", "prodCore_original.pol"
#package_handler = PackageHandler.new "objects_5_0_perimeter_c_duplicates.c"#, "perimeter_original.pol"
#package_handler = PackageHandler.new "objects_5_0_perimeter_c_unused.c"#, "perimeter_original.pol"


#package_handler.objects_handler.objects.push CpHost.new("nasko_test_host_2", IPAddress("255.254.251.252/32"))

titles = Array.new
$tufin_unused_rules.each do |rule_id|
    rule = package_handler.policy_handler.rules.find{|r| r.index==rule_id}
    rule.name = "#zero"
end


# Exports
puts
puts "------>> Exporting Files (~10s)"
package_handler.export_objects "objects_5_0_perimeter_custom.c"
package_handler.export_policy "perimeter_custom.pol"