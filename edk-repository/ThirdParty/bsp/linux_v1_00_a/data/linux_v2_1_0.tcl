#
# EDK BSP generator for Linux supporting Microblaze
#
# (C) Copyright 2010
# Li-Pro.Net <www.li-pro.net>
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

#############################################################################
#   Exported variables
#
variable pkg_name
variable pkg_version
variable linux_verstr

#############################################################################
#  Package meta
#
set pkg_name "linux"
set pkg_version "1.00.a"

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
set linux_verstr [get_version_string ${pkg_name} ${pkg_version}]

#############################################################################
#   DRC			the name of the DRC given in the MLD file
#			(DRC => Design Rule Check)
#
proc linux_drc {os_handle} {
	variable linux_verstr
	debug info "\#--------------------------------------"
	debug info "\# ${linux_verstr} BSP DRC...!"
	debug info "\#--------------------------------------"
}

#############################################################################
#   generate		Libgen defined procedure called after OS and library
#			files are copied
#
proc generate {os_handle} {
	variable linux_verstr
	debug info "\#--------------------------------------"
	debug info "\# ${linux_verstr} BSP generate..."
	debug info "\#--------------------------------------"
	generate_linux $os_handle
}

#############################################################################
#   post_generate	Libgen defined procedure called after generate has
#			been called on all OSs, drivers, and libraries
#
proc post_generate {lib_handle} {
	# This generates the drivers directory for linux
	# and runs the ltypes script
}

#############################################################################
#   Local functions
#
proc generate_linux {os_handle} {
	variable linux_verstr
	set cfg_file_ac [open_project_file "auto-config.in" "Linux 2.4 Configurations" ${linux_verstr}]
	set cfg_file_kc [open_project_file "Kconfig.auto" "Linux 2.6 Configurations" ${linux_verstr}]

	puts ${cfg_file_ac} "\# Project name"
	puts ${cfg_file_ac} "define_string CONFIG_PROJECT_NAME [file tail [get_project_folder]]\n"

	puts ${cfg_file_kc} "\# PTXdist section key: this is part of the Xilinx BSP for a SoftCPU"
	puts ${cfg_file_kc} "\#\# SECTION=xlbsp_softcpu\n"
#	puts ${cfg_file_kc} "\# Project name"
#	puts ${cfg_file_kc} "comment \"Project name\"\n"
#	puts ${cfg_file_kc} "config PROJECT_NAME"
#	puts ${cfg_file_kc} "\tstring \"Project name\""
#	puts ${cfg_file_kc} "\tdefault \"[file tail [get_project_folder]]\"\n\n"

	variable pkg_name
	put_pkg_cfg ${pkg_name} ${cfg_file_ac} ${os_handle}
	put_pkg_cfg ${pkg_name} ${cfg_file_kc} ${os_handle}

	close ${cfg_file_kc}
	close ${cfg_file_ac}
}


