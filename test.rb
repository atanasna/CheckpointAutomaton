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

package_handler = PackageHandler.new "objects_5_0_perimeter_original.c", "perimeter_original.pol"
#package_handler = PackageHandler.new "objects_5_0_perimeter_c_duplicates.c"#, "perimeter_original.pol"
#package_handler = PackageHandler.new "objects_5_0_perimeter_c_unused.c"#, "perimeter_original.pol"

unused_objects_in_policy = package_handler.find_unused_objects_in_policy


start_time = Time.now
i = 0
for_deletion = Array.new
while true
    i+=1
    ap "S: Iteration: #{i} ------------------------------------"
    
    ap "S: CP_default_Office_Mode_addresses_pool exist? : #{not package_handler.objects_handler.find("CP_default_Office_Mode_addresses_pool").nil?}"
    raw = package_handler.objects_handler.generate_raw
    ap "S: Raw lines: #{raw.size}"
    raw = raw.join(' ')

    real_unused = Array.new
    ap "S: Real Unused: #{real_unused.size}"
    ap "S: Objects Count: #{package_handler.objects_handler.objects.size}"
    unused_objects_in_policy.each do |obj|
        if raw.scan(/#{obj.name}/).size == 2
            real_unused.push obj
        end
    end

    if real_unused.empty?
        break
    end

    counter = 0
    real_unused.each do |u|
        obj = package_handler.objects_handler.find u.name
        if not obj.nil?
            for_deletion.push obj
            package_handler.objects_handler.objects.delete(obj)
            counter +=1
        else
            
        end
    end
    ap "E: Real unsued: #{real_unused.size}"
    ap "E: 1st Real unsued: #{real_unused[0].name}"
    ap "E: Groups real: #{real_unused.find_all{|obj| obj.class.name == 'CpGroup'}.size}"
    ap "E: Deleted: #{counter}"
    ap "E: Objects Count: #{package_handler.objects_handler.objects.size}"
end
ap "For Deletion: #{for_deletion.size}"
ap "Time: #{Time.now - start_time}"

ap ""
ap ""
for_deletion.each do |el|
    ap el.name
end