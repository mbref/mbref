#
#	File: top_v2_1_0.tcl
#	Owner: Michal Simek
#
#	Copyright C - 2008 All rights reserved. Michal Simek
#
#	No part of this program may be reproduced or adapted in any form
#	or by any means, electronic or mechanical, without permission from
#	Michal Simek. This program is confidential and may not be disclosed,
#	decompiled or reverse engineered without permission in writing from
#	Michal Simek
#	===================================================================
#
#	Michal Simek - top level generator
#
#	Calling PetaLinux BSP is permitted from Petalogix
#

set top_version "top_v1_00_b"
set ecos_version "ecos_v1_00_a"
set fdt_version "fdt_v1_00_a"
set uboot_version "uboot_v4_00_c"
set petalogix_version "petalinux_v1_00_b"
# not use now set standalone_version "standalone_v1_00_a"
set os ""

# Create a namespace that incorporates the standalone BSP functionality
# Standalone
proc create_standalone_namespace {name os_handle} {
	namespace eval standalone_bsp {
		global env
		set edk_path $env(XILINX_EDK)
		source ${edk_path}/sw/lib/bsp/standalone_v1_00_a/data/standalone_v2_1_0.tcl
	}
	set orig_mbsrcdir "${standalone_bsp::edk_path}/sw/lib/bsp/standalone_v1_00_a/src/microblaze"
	set orig_ppcsrcdir "${standalone_bsp::edk_path}/sw/lib/bsp/standalone_v1_00_a/src/ppc405"
	set orig_profilesrcdir "${standalone_bsp::edk_path}/sw/lib/bsp/standalone_v1_00_a/src/profile"
	set mbsrcdir "./src/microblaze"
	set ppcsrcdir "./src/ppc405"
	set profilesrcdir "./src/profile"

#	file mkdir "./../$name"
	cd "./../$name"

	file mkdir "./src"
	file copy ${orig_mbsrcdir} $mbsrcdir
	file copy ${orig_ppcsrcdir} $ppcsrcdir
	file copy ${orig_profilesrcdir} $profilesrcdir
	puts "Calling standalone::generate"

	standalone_bsp::generate $os_handle
}

proc create_namespace {path name os_handle} {
	namespace eval bsp {
#--M-- exported function from calling outside of namespace
		namespace export find
#--M-- shared variable which can be changed
		variable bsp_name
#--M-- procedure for setting fdt_bsp
		proc find {bsp_name path} {
#--M-- variable from fdt script
			variable cpunumber
			variable periphery_array
			variable version
			variable uartlite_count
			variable mac_count
			variable debug_level
			variable gpio_count
			variable uart16550_count
#--M-- setting of variable
#--M-- bsp_name - full_name; short_name - only the name without version
			set tcl_name [string range $bsp_name 0 [string first "_" $bsp_name]]
			append tcl_name "v2_1_0.tcl"
			puts "\nBSP name: $bsp_name $tcl_name"

			foreach arg $path {
				set full_path "$arg/$bsp_name/data/$tcl_name"
#				puts "$full_path"
				set code [catch {source $full_path} string]
				case $code {
					0 {
						puts "I found tcl_script in $full_path"
						return 0
					}
					1 {
#						puts "not found in EDK installation $full_path"
					}
					default {error "Another problem"}
				}
			}
			puts "$bsp_name is not find in pathes $path"
			return 1
		}
	}
	if { ![bsp::find $name $path] } {
		puts "Calling $name ::generate"
		file mkdir "./../$name"
		cd "./../$name"
		bsp::generate $os_handle
	}
}

proc top_drc {os_handle} {
	variable top_version
	puts "\#-------------------------------------------------"
	puts "\# Top Level BSP DRC for U-BOOT, FDT, Petalinux..."
	puts "\# Created by: Michal Simek"
	puts "\# version: $top_version"
	puts "\#-------------------------------------------------"
}

#--M-- Windows needs to fix path name
proc fix_path {project_folder} {
	variable os
	if { $os == "win" } {
			puts "Windows"
			if { [ string match "/cygdrive/*" $project_folder ] == 1 } {
				regsub "/cygdrive/" $project_folder "" project_folder
				set drive [string index $project_folder 0]
				regsub "$drive" $project_folder "$drive:" project_folder
				unset drive
			} else {
				if { [ string match "/ecos-f/*" $project_folder ] == 1 } {
					regsub "/ecos-" $project_folder "" project_folder
					set drive [string index $project_folder 0]
					regsub "$drive" $project_folder "$drive:" project_folder
					unset drive
				}
			}
	}
	return $project_folder
}

# Adding all posible paths
# Priority level:
#	1. bsp folder in project
#	2. folders in xmp file (ModuleSearchPath)
#	3. subfolders in folders in xmp file
#	4. standard EDK repository
proc get_path {} {
	global env
	variable os
#--M-- repository in project
	set project_folder "[fix_path [exec pwd]]/../../.."
	puts "Project folder is $project_folder"
	set path "$project_folder/bsp/ "

#--M-- finding location inside bsp folder - dangerous for recursive calls - needs tested
	set xmp [exec ls "$project_folder/" | grep ".xmp"]
	set searchpath ""
	foreach act_xmp $xmp {
		puts $act_xmp
		if { $os == "win" } {
			catch {exec cat "$project_folder/$act_xmp" | grep "ModuleSearchPath" | cut -d ":" -f 2- | sed -e 's/\\/*$//' } cesta
		}
		if { $os == "lin" } {
			catch {exec cat "$project_folder/$act_xmp" | grep "ModuleSearchPath" | cut -d ":" -f 2- | sed -e "s/\\/*$//" | sed -e "s/^ *//"} cesta
		}
		puts "---- $cesta ---"
#remove problem with unexisted files in folder
		if { ![regsub "child" $cesta "" ""] } {
#Append only PATH which is not in searchpath
#test on absolute or relative path on Linux
			if { $os == "lin"} {
				if { [string index $cesta 0] == "/" } {
					puts "absolute path"
				} else {
					puts "relative path"
					set cesta "$project_folder/$cesta"
				}
			}
			if { ![regsub $cesta $searchpath "" ""] } {
				puts "$cesta isn't in $searchpath"
				append searchpath "$cesta "
			} else {
				puts "$cesta is in $searchpath"
			}
		}
	}

#--M-- add actual folder in case that folder exists
	append path "$searchpath "
	foreach act_path $searchpath {
		puts "DEBUG: $act_path"

		catch {exec ls -R "$act_path" | grep "bsp:" | sed -e "s/:$//" } prom
		puts "DEBUGprom: $prom"
		foreach loc $prom {
#			puts "DEBUGloc: $loc"
			if { $os == "win" } {
				if {[regsub "$act_path/" $loc "$loc" cesta]} {
					puts "DEBUGlocA: $loc"
					append path "$loc/ "
				}
			}
			if { $os == "lin" } {
# differences between Linux and Windows - Linux support symlinks but ls -R show full path - I can't
# remove only part of path. Add all patches
#				puts "Linux"
				append path "$loc/ "
			}
		}
	}
#--M-- find EDK instalation
	append path "$env(XILINX_EDK)/sw/lib/bsp/ "

	puts "------------BEGIN PATH------------------------"
	puts $path
	puts "------------END PATH--------------------------"
	return $path
}

# generate
proc generate {os_handle} {
	variable os

	global tcl_platform
	switch -glob $tcl_platform(os) {
		"Windows*" {
			set os "win"
		}
		"Linux" {
			set os "lin"
		}
		default {
			error "ERROR: Not tested on $tcl_platform(os) platform"
		}
	}

#--M-- finding all posible patches in Windows or Linux format
	set path [get_path]

	variable ecos_version
	create_namespace $path $ecos_version $os_handle

	variable fdt_version
	create_namespace $path $fdt_version $os_handle

	variable uboot_version
	create_namespace $path $uboot_version $os_handle

	variable petalogix_version
	create_namespace $path $petalogix_version $os_handle

#standalone part must be after petalogix
	variable top_version
#--M-- standalone part
	if {[ catch {exec test -d src } "" ]} {
		puts "\#--------------------------------------"
		puts "\# Standalone BSP generate..."
		puts "\#--------------------------------------"
#you must use top_version - because
		create_standalone_namespace $top_version $os_handle
	} else {
		file copy "./src/" "./../$top_version/src/"
	}
}

# post_generate process
proc post_generate {lib_handle} {
	standalone_bsp::post_generate ${lib_handle}
}

