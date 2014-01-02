#
# EDK BSP generator for U-boot supporting Microblaze and PPC
#
# (C) Copyright 2007-2008 Michal Simek
# Michal SIMEK <monstr@monstr.eu>
#
# (C) Copyright 2010-2014 Li-Pro.Net
# Stephan Linz <linz@li-pro.net>
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
# Project description at http://www.monstr.eu/uboot/
#

#############################################################################
#   Exported variables
#
variable pkg_name
variable pkg_version
variable uboot_verstr

#############################################################################
#  Package meta
#
set pkg_name "uboot"
set pkg_version "4.02.a"

#############################################################################
#   Globals functions
#
if { ![namespace exists ::sw_tpos_misclib] } {
	namespace eval ::sw_tpos_misclib source "../../../lib/tpos_misclib.tcl"
}
namespace import ::sw_tpos_misclib::debug
namespace import ::sw_tpos_misclib::get_version_string
namespace import ::sw_tpos_misclib::direct_path
namespace import ::sw_tpos_misclib::get_project_folder
namespace import ::sw_tpos_misclib::open_project_file
namespace import ::sw_tpos_misclib::put_pkg_cfg

#############################################################################
#   Global variables
#
set uboot_verstr [get_version_string ${pkg_name} ${pkg_version}]

#############################################################################
#   DRC			the name of the DRC given in the MLD file
#			(DRC => Design Rule Check)
#
proc uboot_drc {os_handle} {
	variable uboot_verstr
	debug info "\#--------------------------------------"
	debug info "\# ${uboot_verstr} BSP DRC...!"
	debug info "\#--------------------------------------"
}

#############################################################################
#   generate		Libgen defined procedure called after OS and library
#			files are copied
#
proc generate {os_handle} {
	variable uboot_verstr
	debug info "\#--------------------------------------"
	debug info "\# ${uboot_verstr} BSP generate..."
	debug info "\#--------------------------------------"
	generate_uboot $os_handle
}

#############################################################################
#   post_generate	Libgen defined procedure called after generate has
#			been called on all OSs, drivers, and libraries
#
proc post_generate {lib_handle} {
	# This generates the drivers directory for uboot
	# and runs the ltypes script
}

#############################################################################
#   Local functions
#
proc generate_uboot {os_handle} {
	variable uboot_verstr
	set cfg_file_mk [open_project_file "config.mk" "U-Boot Configurations" ${uboot_verstr}]
	set cfg_file_h [open_project_file "xparameters.h" "U-Boot Configurations" ${uboot_verstr}]

	#
	# xparameters.h
	#
	puts ${cfg_file_h} "/* Project name */"
	puts ${cfg_file_h} "#define XILINX_BOARD_NAME\t\"[file tail [get_project_folder]]\"\n"

	variable pkg_name
	put_pkg_cfg ${pkg_name} ${cfg_file_h} ${os_handle}
	put_pkg_cfg ${pkg_name} ${cfg_file_mk} ${os_handle}

	close ${cfg_file_h}
	close ${cfg_file_mk}
}
