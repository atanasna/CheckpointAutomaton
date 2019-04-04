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

# Loader
    #system('cls')
    puts "< Loader >".rjust(40,"=").ljust(90,"=")
    puts
    puts "------>> Loading Files(~50s)"
    #package_handler = PackageHandler.new "objects_5_0_perimeter_original.C", "perimeter_original.pol"
    package_handler = PackageHandler.new "m_perimeter_objects_5_0.C", "o_nonprod.pol"

# Statister - Before the worker starts
    puts
    puts "< Before-Statister >".rjust(40,"=").ljust(90,"=")
    #puts
    #package_handler.print_objects_stats
    puts
    package_handler.print_policy_stats
    #puts
    #package_handler.print_color_stats

# Worker
    # Remove fully shadowed rules
        #puts
        #package_handler.remove_shadowed_rules_tufin

    # Remove disable rules
        #puts
        #package_handler.remove_disabled_rules
    
    # Tag unsuder rules (if it doesn't have #nonZero tag it with #zero)
        #puts
        #package_handler.tag_unused_rules

    # Remove zerohit rules
        #puts
        #package_handler.remove_unused_rules

    puts "< Middle-Statister >".rjust(40,"=").ljust(90,"=")
    #puts
    #package_handler.print_objects_stats
    puts
    package_handler.print_policy_stats

    #Production - WORKING - NOT Tested
    def split_prod vses, package_handler
        
        vses.each do |vs_name|
            #Find rules per VS
            entries = package_handler.policy_handler.entries_by_vs vs_name
            rules = entries.find_all{|entry| entry.class.name == "CpPolicyRule"}
            puts "-----------------------| #{vs_name}"
            puts "Titles: #{entries.size - rules.size}"
            puts "Rules: #{rules.size}"
            puts "Shared: #{rules.find_all{|rule| rule.installed.size>1}.size}"

            #Generate policy_handler
            policy = Marshal.load(Marshal.dump(package_handler.policy_handler))
            policy.entries = entries

            #Export to file
            puts "------>> Exporting Files (~10s)"
            filename = "resources/#{vs_name}.pol"
            print "Writing #{vs_name} Policy to file . . . "
            File.open(filename, "w+") do |f|
                policy.generate_raw.each { |element| f.puts(element) }
            end
            puts "OK! - #{filename}"
        end
    end

        
    vses = ["NONPROD_EBT_VS","NONPROD_GHO_VS","NONPROD_CORE_VS","PP_DC_SERVICES_VS","NONPROD_DCSERVICES_VS","TS_DC_SERVICES_VS"]
    #vses = ["MGMT_VS","PROD_GHO_VS","PROD_CORE_VS","PROD_DCSERVICES_VS"]
    split_prod vses,package_handler