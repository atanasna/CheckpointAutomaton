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
    system('cls')
    puts "< Loader >".rjust(40,"=").ljust(90,"=")
    puts
    puts "------>> Loading Files(~50s)"
    package_handler = PackageHandler.new "m_perimeter_objects_5_0.C", "m_perimeter.pol"
    #package_handler = PackageHandler.new "objects_5_0_prodCore_original.C", "prodCore_original.pol"

# Statister - Before the worker starts
    puts
    puts "< Before-Statister >".rjust(40,"=").ljust(90,"=")
    puts
    package_handler.print_objects_stats
    puts
    package_handler.print_policy_stats
    puts
    package_handler.print_color_stats

# Worker
    puts
    puts "< Worker >".rjust(40,"=").ljust(90,"=")
    # Rules Manipulation =========================================
    # Remove fully shadowed rules
        #puts
        #package_handler.remove_shadowed_rules_tufin

    # Remove disable rules
        #puts
        #package_handler.remove_disabled_rules
    
    # Tag unsuder rules
        #puts
        #package_handler.tag_unused_rules

    # Remove rules tagged with #zero in the name
        #puts
        #package_handler.remove_unused_rules

    # Create new titles
        #puts
        #package_handler.add_new_titles

    # Objects Manipulation =========================================
    # Remove unused objects - This Doesn't work
        #puts
        #package_handler.remove_unused_objects

    # Remove duplicate objects
        puts
        package_handler.remove_duplicated_objects

    # Replace /32 network objects with hosts
        puts
        package_handler.replace_slash32_networks

    # Rename objects based on the DNS recores
        puts
        package_handler.rename_to_fqdns

    # Colorize
        puts
        package_handler.colorize
 
    # Exports
        puts
        puts "------>> Exporting Files (~10s)"

        package_handler.export_objects "c2_objects_5_0_perimeter.C"
        package_handler.export_policy "c2_perimeter.pol"

# Statister
    puts
    puts "<After-Statister>".rjust(40,"=").ljust(90,"=")
    puts
    package_handler.print_objects_stats
    puts
    package_handler.print_policy_stats
    puts
    package_handler.print_color_stats