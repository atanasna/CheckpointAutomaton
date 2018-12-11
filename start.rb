load "helpers.rb"
require "ipaddress"
load "CpObjectsHandler/cpHost.rb"
load "CpObjectsHandler/cpGroup.rb"
load "CpObjectsHandler/cpNetwork.rb"
load "CpObjectsHandler/cpRange.rb"
load "CpObjectsHandler/cpObjectsHandler.rb"
load "packageHandler.rb"
require "awesome_print"

ap "------------------------- Policy Parser -------------------------"
package_handler = PackageHandler.new

ap "------ In source ------"
ap package_handler.find_rules([IPAddress("10.66.81.1"),IPAddress("10.66.51.128/25")], true, false).map{|rule| rule.index}.join(",")
ap "--- In destination ----"
ap package_handler.find_rules([IPAddress("10.66.81.1"),IPAddress("10.66.51.128/25")], false, true).map{|rule| rule.index}.join(",")

