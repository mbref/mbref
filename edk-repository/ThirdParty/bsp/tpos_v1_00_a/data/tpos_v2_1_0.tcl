#
# EDK BSP generator for third party operating systems
# supporting Microblaze (and PPC ???)
#
# (C) Copyright 2010-2011
# Li-Pro.Net <www.li-pro.net>
# Stephan Linz <linz@li-pro.net>
#
# (C) Copyright 2008 Michal Simek <monstr@monstr.eu>
# Borrowed in parts from uboot_v2_1_0 and device-tree_v2_1_0
# Project description at http://www.monstr.eu/uboot/ and
# http://www.monstr.eu/wiki/doku.php?id=bsp:bsp
#
# Template from:
# http://www.itee.uq.edu.au/~listarch/microblaze-uclinux/archive/2007/11/msg00008.html
# http://www.itee.uq.edu.au/~listarch/microblaze-uclinux/archive/2007/11/msg00025.html
#   http://www.itee.uq.edu.au/~listarch/microblaze-uclinux/archive/2007/11/binl27ir65dZo.bin
#   http://www.itee.uq.edu.au/~listarch/microblaze-uclinux/archive/2007/11/binl2SnmcqdN6.bin
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA
#

# Extraction fomr Xilinx documentation:
# -------------------------------------
# "Platform Specification Format Referende Manual",
#   Chapter 7: Microprocessor Library Definition (MLD)
#
# "Embedded System Tools Reference Manual",
#   Chapter 8: Library Generator (Libgen)
#
#
# Various procedures in a Tcl file include:
#   DRC			the name of the DRC given in the MLD file
#			(DRC => Design Rule Check)
#
#   generate		Libgen defined procedure called after OS and library
#			files are copied
#
#   post_generate	Libgen defined procedure called after generate has
#			been called on all OSs, drivers, and libraries
#
#   execs_generate	Libgen defined procedure called after the BSPs,
#			libraries, and drivers have been generated
#
# You should read:
#   http://wiki.tcl.tk/
#   http://www.tcl.tk/man/
#

#############################################################################
#   Exported variables
#
variable pkg_name
variable pkg_version
variable tpos_verstr

#############################################################################
#  Package meta
#
set pkg_name "tpos"
set pkg_version "1.00.a"

#############################################################################
#   Globals functions
#
if { ![namespace exists ::sw_tpos_misclib] } {
	namespace eval ::sw_tpos_misclib source "../../../lib/tpos_misclib.tcl"
}
namespace import ::sw_tpos_misclib::debug
namespace import ::sw_tpos_misclib::get_version_string
namespace import ::sw_tpos_misclib::get_mld_name
namespace import ::sw_tpos_misclib::direct_path
namespace import ::sw_tpos_misclib::get_project_folder
namespace import ::sw_tpos_misclib::tpos_check_design

#############################################################################
#   Global variables
#
set tpos_verstr [get_version_string ${pkg_name} ${pkg_version}]
set tpos_bsp_path [direct_path "../../../bsp"]

# tpos_bsp packages
set fsboot_name "fsboot"
set fsboot_version_list ${::sw_tpos_misclib::fsboot_version_list}
set xlboot_name "xlboot"
set xlboot_version_list ${::sw_tpos_misclib::xlboot_version_list}
set uboot_name "uboot"
set uboot_version_list ${::sw_tpos_misclib::uboot_version_list}
set linux_name "linux"
set linux_version_list ${::sw_tpos_misclib::linux_version_list}
set devtree_name "device-tree"
set devtree_version_list ${::sw_tpos_misclib::devtree_version_list}

# misc
set os ""

#############################################################################
#   Local functions (tpos_bsp)
#
namespace eval tpos_bsp {
	namespace import ::sw_tpos_misclib::debug
	namespace export find
	proc find {tpos_bsp_name path} {
		set tcl_name [string range ${tpos_bsp_name} 0 [string first "_" ${tpos_bsp_name}]]
		append tcl_name "v2_1_0.tcl"
		debug info "\#--------------------------------------"
		debug info "\# BSP name: ${tpos_bsp_name} ${tcl_name}"
		debug info "\#--------------------------------------"

		debug jabber "Looking for in:"
		foreach arg ${path} {
			set full_path [file join ${arg} ${tpos_bsp_name} "data" ${tcl_name}]
			debug jabber "${full_path}"
			set code [catch {source $full_path} string]
			case $code {
				0 {
					debug info "   ... found"
					return 0
				}
				1 {
					debug warning "   ... not found"
				}
				default {error "Another problem"}
			}
		}
		debug info "\nBSP name: ${tpos_bsp_name} was not found in given pathes!"
		return 1
	}
}

#############################################################################
#   DRC			the name of the DRC given in the MLD file
#			(DRC => Design Rule Check)
#
proc tpos_drc {os_handle} {
	variable tpos_verstr
	debug info "\#--------------------------------------"
	debug info "\# ${tpos_verstr} BSP DRC...!"
	debug info "\#--------------------------------------"
	tpos_check_design ${os_handle}
}

#############################################################################
#   generate		Libgen defined procedure called after OS and library
#			files are copied
#
proc generate {os_handle} {
	variable tpos_verstr
	debug info "\#--------------------------------------"
	debug info "\# ${tpos_verstr} BSP generate..."
	debug info "\#--------------------------------------"
	generate_tpos ${os_handle}
}

#############################################################################
#   post_generate	Libgen defined procedure called after generate has
#			been called on all OSs, drivers, and libraries
#
# complete standalone_bsp process
proc post_generate {os_handle} {
	variable tpos_verstr
	debug info "\#--------------------------------------"
	debug info "\# ${tpos_verstr} BSP post_generate..."
	debug info "\#--------------------------------------"
	#standalone_bsp::post_generate ${os_handle}
}

#############################################################################
#	 execs_generate	Libgen defined procedure called after the BSPs,
#			libraries, and drivers have been generated
#
# complete standalone_bsp process
proc execs_generate {os_handle} {
	variable tpos_verstr
	debug info "\#--------------------------------------"
	debug info "\# ${tpos_verstr} BSP execs_generate..."
	debug info "\#--------------------------------------"
	# HINT: here we could copy the tpos generated files outside to ...
	#standalone_bsp::execs_generate ${os_handle}
}

#############################################################################
#	 Local functions
#
proc generate_tpos {os_handle} {
	variable os
	global tcl_platform
	switch -glob ${tcl_platform(os)} {
		"Windows*" {
			set os "win"
			debug info "Running on Windows..."
		}
		"Linux" {
			set os "lin"
			debug info "Running on Linux..."
		}
		default {
			error "ERROR: Not tested on ${tcl_platform(os)} platform"
		}
	}

	# finding all posible paths in Windows or Linux format
	set path [get_path]

	# apply all bsp parts
	# TODO: make a common probe-and-run procedure
	variable fsboot_name
	variable fsboot_version_list
	set fsboot [xget_sw_parameter_value ${os_handle} "fsboot"]
	if { ${fsboot} } {
		set savewd [pwd]
		tpos_genmod ${path} ${fsboot_name} ${fsboot_version_list} ${os_handle}
		cd ${savewd}
	} else {
		puts "ThirdParty OS part \"${fsboot_name}\" disabled."
	}

	variable xlboot_name
	variable xlboot_version_list
	set xlboot [xget_sw_parameter_value ${os_handle} "xlboot"]
	if { ${xlboot} } {
		set savewd [pwd]
		tpos_genmod ${path} ${xlboot_name} ${xlboot_version_list} ${os_handle}
		cd ${savewd}
	} else {
		puts "ThirdParty OS part \"${xlboot_name}\" disabled."
	}

	variable uboot_name
	variable uboot_version_list
	set uboot [xget_sw_parameter_value ${os_handle} "uboot"]
	if { ${uboot} } {
		set savewd [pwd]
		tpos_genmod ${path} ${uboot_name} ${uboot_version_list} ${os_handle}
		cd ${savewd}
	} else {
		puts "ThirdParty OS part \"${uboot_name}\" disabled."
	}

	variable linux_name
	variable linux_version_list
	set linux [xget_sw_parameter_value ${os_handle} "linux"]
	if { ${linux} } {
		set savewd [pwd]
		tpos_genmod ${path} ${linux_name} ${linux_version_list} ${os_handle}
		cd ${savewd}
	} else {
		puts "ThirdParty OS part \"${linux_name}\" disabled."
	}

	variable devtree_name
	variable devtree_version_list
	set devtree [xget_sw_parameter_value ${os_handle} "devtree"]
	if { ${devtree} } {
		set savewd [pwd]
		tpos_genmod ${path} ${devtree_name} ${devtree_version_list} ${os_handle}
		cd ${savewd}
	} else {
		puts "ThirdParty OS part \"${devtree_name}\" disabled."
	}

	# standalone bsp part must be generate after tpos_bsp
	set savewd [pwd]
	create_standalone_namespace ${os_handle}
	cd ${savewd}
}

# Recursive call to find and calling all generate functions:
proc tpos_genmod {path name version_list os_handle} {
	foreach version ${version_list} {
		if { ![tpos_bsp::find [get_mld_name ${name} ${version}] ${path}] } {
			debug info "Calling ${name}::generate"
			file mkdir [file join "./.." [get_mld_name ${name} ${version}]]
			cd [file join "./.." [get_mld_name ${name} ${version}]]
			tpos_bsp::generate ${os_handle}
			return
		}
	}
}

# Create a namespace that incorporates the standalone BSP functionality
proc create_standalone_namespace {os_handle} {
	namespace eval standalone_bsp {
		namespace import ::sw_tpos_misclib::get_mld_name
		global env
		set edk_path ${env(XILINX_EDK)}
		set version_list [list 3.00.a 2.00.a 1.00.a]
		foreach version ${version_list} {
			set mdl_path [file join ${edk_path} "sw/lib/bsp" [get_mld_name "standalone" ${version}]]
			set mdl_file [file join ${mdl_path} "data/standalone_v2_1_0.tcl"]
			if { [file exists $mdl_file] } {
				source $mdl_file
				break
			}
		}
	}

	set standalone_verstr [get_version_string "standalone" ${standalone_bsp::version}]
	debug info "\#--------------------------------------"
	debug info "\# ${standalone_verstr} BSP prepare..."
	debug info "\#--------------------------------------"

	set orig_mbsrcdir [file join ${standalone_bsp::edk_path} ${standalone_bsp::mdl_path} "src/microblaze"]
	set orig_ppc405srcdir [file join ${standalone_bsp::edk_path} ${standalone_bsp::mdl_path} "src/ppc405"]
	set orig_ppc440srcdir [file join ${standalone_bsp::edk_path} ${standalone_bsp::mdl_path} "src/ppc440"]
	set orig_profilesrcdir [file join ${standalone_bsp::edk_path} ${standalone_bsp::mdl_path} "src/profile"]
	set orig_commonsrcdir [file join ${standalone_bsp::edk_path} ${standalone_bsp::mdl_path} "src/common"]

	set mbsrcdir "./src/microblaze"
	set ppc405srcdir "./src/ppc405"
	set ppc440srcdir "./src/ppc440"
	set profilesrcdir "./src/profile"
	set commonsrcdir "./src/common"

	debug info "Copying source directories:"
	# TODO: make a common copy procedure
	if { [file isdirectory ${orig_mbsrcdir}] } {
		debug info "${orig_mbsrcdir}"
		file mkdir [file dirname ${mbsrcdir}]
		file copy ${orig_mbsrcdir} ${mbsrcdir}
	}
	if { [file isdirectory ${orig_ppc405srcdir}] } {
		debug info "${orig_ppc405srcdir}"
		file mkdir [file dirname ${ppc405srcdir}]
		file copy ${orig_ppc405srcdir} ${ppc405srcdir}
	}
	if { [file isdirectory ${orig_ppc440srcdir}] } {
		debug info "${orig_ppc440srcdir}"
		file mkdir [file dirname ${ppc440srcdir}]
		file copy ${orig_ppc440srcdir} ${ppc440srcdir}
	}
	if { [file isdirectory ${orig_profilesrcdir}] } {
		debug info "${orig_profilesrcdir}"
		file mkdir [file dirname ${profilesrcdir}]
		file copy ${orig_profilesrcdir} ${profilesrcdir}
	}
	if { [file isdirectory ${orig_commonsrcdir}] } {
		debug info "${orig_commonsrcdir}"
		file mkdir [file dirname ${commonsrcdir}]
		file copy ${orig_commonsrcdir} ${commonsrcdir}
	}

	debug info "Calling standalone::generate"
	debug info "\#--------------------------------------"
	debug info "\# ${standalone_verstr} BSP generate..."
	debug info "\#--------------------------------------"
	standalone_bsp::generate ${os_handle}
}

# if we need fixed path name do it here
proc fix_path {path} {
	variable os
	if { ${os} == "win" } {
		if { [string match "/cygdrive/*" ${path}] } {
			regsub "/cygdrive/" ${path} "" path
			set drive [string index ${path} 0]
			regsub "$drive" ${path} "$drive:" path
			unset drive
		} else {
			if { [string match "/ecos-f/*" ${path}] } {
				regsub "/ecos-" ${path} "" path
				set drive [string index ${path} 0]
				regsub "$drive" ${path} "$drive:" path
				unset drive
			}
		}
	}
	return ${path}
}

# Adding all posible paths
# Priority level:
#	1. bsp folder in project
#	2. bsp folder in script path
#	3. folders in xmp files (ModuleSearchPath)
#	4. subfolders in folders in xmp files
#	5. standard EDK repository
# TODO: handle spaces in path names
# OBSOLETE: in one of next versions step 3 and 4 (xmp file parsing)
#           will be removed
proc get_path {} {
	global env
	variable os
	variable tpos_bsp_path

	set project_folder [get_project_folder]
	debug info "Project folder is ${project_folder}"

	# (1) bsp folder in project
	set path [file join ${project_folder} "bsp"]
	set path [direct_path ${path}]

	# (2) bsp folder in script path
	lappend path ${tpos_bsp_path}

	# finding location inside xps folder
	set project_xmp [glob -nocomplain -type f -directory ${project_folder} *.xmp]
	set searchpath ""
	foreach act_xmp ${project_xmp} {
		debug info "Parse XMP file ${act_xmp}"
		if { ${os} == "win" } {
			catch {
				exec cat [file join ${project_folder} ${act_xmp}] | \
					grep "ModuleSearchPath" | cut -d ":" -f 2- | \
					sed -e 's/\\/*$//'
			} cesta
		}
		if { ${os} == "lin" } {
			catch {
				exec cat [file join ${project_folder} ${act_xmp}] | \
					grep "ModuleSearchPath" | cut -d ":" -f 2- | \
					sed -e "s/\\/*$//" | sed -e "s/^ *//"
			} cesta
		}
		debug jabber "---- ${cesta} ---"
		# remove problem with unexisted files in folder
		if { ![regsub "child" ${cesta} "" ""] } {
			debug jabber "   ... path exists, make it absolut and direct"
			set cesta [file join ${project_folder} ${cesta}]
			set cesta [direct_path ${cesta}]
			# append only PATH which is not in searchpath
			if { ![regsub ${cesta} ${searchpath} "" ""] } {
				debug jabber "   ... is not in searchpath, append it"
				lappend searchpath ${cesta}
			} else {
				debug jabber "   ... is already in searchpath"
			}
		}
	}

	# (3) folders in xmp files (ModuleSearchPath)
	lappend path ${searchpath}

	# add actual folder in case that folder exists
	foreach act_path ${searchpath} {
		debug info "Parse XMP directory ${act_path}"
		catch {
			exec ls -R "${act_path}" | grep "bsp:" | sed -e "s/:$//"
		} prom
		set searchpath ""
		foreach cesta ${prom} {
			debug jabber "---- ${cesta} ---"
			debug jabber "   ... make it absolut and direct"
			set cesta [file join ${act_path} ${cesta}]
			set cesta [direct_path ${cesta}]
			# append only PATH which is not in searchpath
			if { ![regsub ${cesta} ${searchpath} "" ""] } {
				debug jabber "   ... is not in searchpath, append it"
				lappend searchpath ${cesta}
			} else {
				debug jabber "   ... is already in searchpath"
			}
		}
	}

	# (4) subfolders in folders in xmp files
	lappend path ${searchpath}

	# find EDK instalation
	set edk_path ${env(XILINX_EDK)}
	set cesta [file join ${edk_path} "sw/lib/bsp"]
	set searchpath [direct_path ${cesta}]

	# (5) standard EDK repository
	lappend path ${searchpath}

	# puts result
	debug info "---------BEGIN PATH---------------------"
	foreach pn ${path} { debug info ${pn} }
	debug info "---------END PATH-----------------------"
	return ${path}
}
