require_relative "helpers.rb"
require_relative "CpObjectsHandler/cpHost.rb"
require_relative "CpObjectsHandler/cpGroup.rb"
require_relative "CpObjectsHandler/cpNetwork.rb"
require_relative "CpObjectsHandler/cpRange.rb"
require_relative "CpObjectsHandler/cpObjectsHandler.rb"
require_relative "packageHandler.rb"
require_relative "../topographer/topographer.rb"
require_relative "ipMapping.rb"
require "ipaddress"
require "awesome_print"

#system('cls')
puts "------------------------- CP Automaton -------------------------"
package_handler = PackageHandler.new "objects_5_0_perimeter_original.c", "standard-clone.pol"
topo = Topographer.new "../topographer/json_graph"

package_handler.stats_objects
package_handler.stats_policy
#ap package_handler.objects_handler.objects.size

#ap "------ In source ------"
#ap package_handler.find_rules([IPAddress("10.66.81.1"),IPAddress("10.66.51.128/25")], true, false).map{|rule| rule.index}.join(",")
#ap "--- In destination ----"
#ap package_handler.find_rules([IPAddress("10.66.81.1"),IPAddress("10.66.51.128/25")], false, true).map{|rule| rule.index}.join(",")

# Coloring
puts "Start coloring . . ."
internal_vses = Array.new
internal_vses.push topo.graph.find "PROD_CORE_VS"
internal_vses.push topo.graph.find "MGMT_VS"
internal_vses.push topo.graph.find "PROD_GHO_VS"
internal_vses.push topo.graph.find "PROD_DCSERVICES_VS"
internal_vses.push topo.graph.find "NONPROD_EBT_VS"
internal_vses.push topo.graph.find "NONPROD_CORE_VS"
internal_vses.push topo.graph.find "NONPROD_GHO_VS"
internal_vses.push topo.graph.find "PP_DC_SERVICES_VS"
internal_vses.push topo.graph.find "TS_DC_SERVICES_VS"
internal_vses.push topo.graph.find "NONPROD_DCSERVICES_VS"

perimeter_vses = Array.new
perimeter_vses.push topo.graph.find "PROD_PERIMETER_VS"

internal_vlans = Array.new
internal_vses.each do |vs|
    internal_vlans += topo.graph.get_vlans_behind_vs vs
end

perimeter_vlans = Array.new
perimeter_vses.each do |vs|
    perimeter_vlans += topo.graph.get_vlans_behind_vs vs
end

group = package_handler.objects_handler.groups.find{|g| g.name=="INFR_OMBS_DCs"}

puts "-------------- Coloring Statistics ----------------"
print "coloring all . . . "
print package_handler.objects_handler.coloring [IPAddress("0.0.0.0/0")], "firebrick"
puts " objects colored in firebrick"

print "coloring core . . . "
print package_handler.objects_handler.coloring $dc_subnets, "olive"
puts " objects colored in olive"

print "coloring dmz . . . "
print package_handler.objects_handler.coloring $dmz_subnets, "orange"
puts " objects colored in orange"

print "coloring office . . . "
print package_handler.objects_handler.coloring $office_subnets, "gold"
puts " objects colored in gold"

print "coloring roadWarriors . . . "
print package_handler.objects_handler.coloring $rw_subnets, "dark gold"
puts " objects colored in dark gold"
puts "--------------------------------------------------"

print "Writing new Objects to file . . . "
new_obj = package_handler.objects_handler.generate_raw

File.open("objects_5_0_perimeter_custom.c", "w+") do |f|
    new_obj.each { |element| f.puts(element) }
end
puts "done"