#
# EDK BSP board generation for third party operating systems misclib
#
# (C) Copyright 2010
# Li-Pro.Net <www.li-pro.net>
# Stephan Linz <linz@li-pro.net>
#
# (C) Copyright 2008 Michal Simek <monstr@monstr.eu>
# Borrowed in parts from uboot_v2_1_0 and device-tree_v2_1_0
# Project description at http://www.monstr.eu/uboot/ and
# http://www.monstr.eu/wiki/doku.php?id=bsp:bsp
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

# MLD nameing mechanism:
set tpos_version_list [list 1.00.a]
set fsboot_version_list [list 1.00.a]
set xlboot_version_list [list 1.00.a]
set uboot_version_list [list 4.02.a 4.01.a]
set linux_version_list [list 1.00.a]
set devtree_version_list [list 1.02.a]

variable put_cfg_procs
set put_cfg_procs(fsboot) {
	put_timer_cfg	put_sysmem_cfg	put_normem_cfg	put_uart_cfg
}
set put_cfg_procs(xlboot) {
	put_timer_cfg	put_sysmem_cfg	put_normem_cfg	put_uart_cfg
}
set put_cfg_procs(uboot) {
	put_timer_cfg	put_sysmem_cfg	put_normem_cfg	put_uart_cfg
	put_iic_cfg	put_gpio_cfg	put_sysace_cfg	put_ethmac_cfg
}
set put_cfg_procs(linux) {
	put_timer_cfg	put_sysmem_cfg	put_normem_cfg
}
set put_cfg_procs(devtree) {
}


namespace export get_version_string
proc get_version_string {name version} {
	return ${name}-v${version}
}

namespace export get_mld_name
proc get_mld_name {name version} {
	return [string map {. _} ${name}_v${version}]
}

# Debug mechanism:
# Uncomment one or more of lines below to get ...:
#	info		... general progress messages.
#	warning		... warnings about BSP usage.
#	jabber		... all and fancy progress messages.
#	clock		... a summary of clock analysis.
#	ip		... verbose IP information.
#	cpu		... verbose processor information.
#	handles		... debugging information about EDK handles.
set debug_level {}
lappend debug_level [list "info"]
lappend debug_level [list "warning"]
# lappend debug_level [list "jabber"]
# lappend debug_level [list "clock"]
lappend debug_level [list "ip"]
lappend debug_level [list "cpu"]
# lappend debug_level [list "handles"]

# help function for debug purpose
namespace export debug
proc debug {level string} {
	variable debug_level
	if {[lsearch $debug_level $level] != -1} {
		puts $string
	}
}

# correct to direct and/or real path name
# comes from: http://wiki.tcl.tk/773
namespace export direct_path
proc direct_path {path} {
	set savewd [pwd]
	set realpath [file join ${savewd} ${path}]
	# always gives a canonical directory name
	cd [file dirname ${realpath}]
	set dir [pwd]
	set path [file tail ${realpath}]
	while { ![catch {file readlink ${path}} realpath] } {
		# always gives the real canonical directory name
		cd [file dirname ${realpath}]
		set dir [pwd]
		set path [file tail ${realpath}]
	}
	cd ${savewd}

	return [file join ${dir} ${path}]
}

# creating the project_folder as an absolute name
# project directory is at any level above as libgen calls the tcl from
namespace export get_project_folder
proc get_project_folder {} {
	set path [pwd]
	while { ${path} != "/" } {
		set project_xmp [glob -nocomplain -type f -directory ${path} *.xmp]
		if {[llength ${project_xmp}]} {
			return [direct_path ${path}]
		}
		set path [file dirname ${path}]
	}

	return [pwd]
}

# simple database to save channelid with corresponding
# filename as will need by get_file_type()
array set chid2fn {}
proc set_chid2fn {chid fn} {
	variable chid2fn
	set chid2fn($chid) ${fn}
}
proc get_chid2fn {chid} {
	variable chid2fn
	return $chid2fn($chid)
}

# build a file type string, returns:
#   ch   - C/C++ source or header file
#   mk   - Make file (mainly GNU Make)
#   kc24 - Kernel-config 2.4
#   kc26 - Kernel-config 2.6
proc get_file_type {fh_fn} {
	# distinguish file handle from file name
	if {[file isfile ${fh_fn}]} {
		# is a simple filename
		set fext [file extension ${fh_fn}]
		set fname [file tail ${fh_fn}]
	} elseif {[file channels ${fh_fn}] == "${fh_fn}"} {
		# is a file channel --  convert back to
		# filename by simple database chid2fn
		set fext [file extension [get_chid2fn ${fh_fn}]]
		set fname [file tail [get_chid2fn ${fh_fn}]]
	}
	# first of all probe per file extension
	switch [string tolower ${fext}] {
		.h -
		.c -
		.cpp	{ return "ch" }
		.mk	{ return "mk" }
		default {}
	}
	# then probe per file name
	switch [string tolower ${fname}] {
		auto-config.in	{ return "kc24" }
		kconfig.auto	{ return "kc26" }
		makefile	{ return "mk" }
		default		{ return "" }
	}
}

# Open files and print GPL licence
# derived from xopen_include_file()
namespace export open_project_file
proc open_project_file {file_name desc vers} {
	#set filename [file join ${file_path} ${file_name}]
	if {[file exists ${file_name}]} {
		set config_file [open ${file_name} a]
		set_chid2fn ${config_file} ${file_name}
	} else {
		set config_file [open ${file_name} w]
		set_chid2fn ${config_file} ${file_name}
		set ft [get_file_type ${file_name}]
		switch ${ft} {
			ch	{ put_ch_header ${config_file} ${desc} ${vers} }
			mk	{ put_mk_header ${config_file} ${desc} ${vers} }
			kc24	{ put_kc24_header ${config_file} ${desc} ${vers} }
			kc26	{ put_kc26_header ${config_file} ${desc} ${vers} }
			default	{
				debug warning "WARNING: No header, unknown type: ${ft}"
			}
		}
	}
	return ${config_file}
}

# remove pattern from beginning of string
proc string_trimleft_pat {str pat} {
	set psz [string length ${pat}]
	set pst [string first ${pat} ${str} 0]
	if { ${pst} >= 0 && ${pst} < ${psz} } {
		set lst [string length ${str}]
		set fst ${psz}
		return [string range ${str} ${fst} ${lst}]
	}
	# nothing to do
	return ${str}
}

#
# DRC
#
namespace export tpos_check_design
proc tpos_check_design {osh} {
	#
	# Design needs Interrupt controller
	#
	set intc_handle [get_intc_handle]
	if {[string match "" ${intc_handle}] || [string match -nocase "none" ${intc_handle}]} {
		debug info "INFO: Please specify intc in projects MSS."
		error "ERROR: Interrupt controller not specified."
	}
	# TODO: redesign test_buses - give name of buses from IP
	test_buses [get_system_bus] ${intc_handle} "SOPB"
	debug info "INFO: Interrupt controller specified."

	#
	# Design needs Timer
	#
	set timer [xget_sw_parameter_value ${osh} "timer"]
	if {[string match "" ${timer}] || [string match -nocase "none" ${timer}]} {
		debug info "INFO: Please specify timer in projects MSS."
		error "ERROR: Timer not specified."
	}
	set timer_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] ${timer}]
	# TODO: redesign test_buses - give name of buses from IP
	test_buses [get_system_bus] ${timer_handle} "SOPB"
	debug info "INFO: Timer specified."

	#
	# Design needs system memory (RAM)
	#
	set sysmem [xget_sw_parameter_value ${osh} "main_memory"]
	set sysmem_bank [xget_sw_parameter_value ${osh} "main_memory_bank"]
	if {[string match "" ${sysmem}] || [string match -nocase "none" ${sysmem}]} {
		debug info "INFO: Please specify main_memory in projects MSS."
		error "ERROR: System memory not specified."
	}
	debug info "INFO: System memory specified."
	set sysmem_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] ${sysmem}]
	if {[xget_hw_value ${sysmem_handle}] == "mpmc"} {
		set parapre MPMC
	} else {
		set parapre [format MEM%i ${sysmem_bank}]
	}
	set eram_base [get_addr_hex ${sysmem_handle} [format C_%s_BASEADDR ${parapre}]]
	debug info "      eram_base := ${eram_base}"

	#
	# Design can have NOR flash memory (ROM)
	# If so check address map.
	#
	set normem [xget_sw_parameter_value ${osh} "flash_memory"]
	set normem_bank [xget_sw_parameter_value ${osh} "flash_memory_bank"]
	if {[string match "" ${normem}] || [string match -nocase "none" ${normem}]} {
		debug info "INFO: Please specify flash_memory in projects MSS."
		debug info "      NOR Flash memory not specified."
	} else {
		set normem_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] ${normem}]
		set flash_type [xget_hw_value ${normem_handle}]
		switch -exact ${flash_type} {
			"xps_spi" {
				debug info "INFO: Serial SPI Flash memory specified."
			}
			default {
				debug info "INFO: Parallel NOR Flash memory specified."
				set parapre [format C_MEM%i ${normem_bank}]
				set flash_base [get_addr_hex ${normem_handle} [format %s_BASEADDR ${parapre}]]
				debug info "      flash_base := ${flash_base}"

				# check address position between System memory and Flash
				debug info "INFO: Check address map (ROM < RAM)."
				if {$eram_base >= $flash_base} {
					error "ERROR: Flash base address must be on higher address than ram memory"
				} else {
					debug info "      ${eram_base} < ${flash_base}"
				}
			}
		}
	}

	#
	# Design can have LLTEMAC Ethernet
	# If so check bus connection.
	#
	set ethmac [xget_sw_parameter_value ${osh} "ethernet"]
	if {[string match "" ${normem}] || [string match -nocase "none" ${normem}]} {
		debug info "INFO: Ethernet not specified."
	} else {
		set ethmac_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] ${ethmac}]
		set ethmac_type [xget_hw_value ${ethmac_handle}]
		switch -exact ${ethmac_type} {
			"xps_ll_temac" {
				debug info "INFO: LLTEMAC Ethernet specified."
				set llink_handle [get_lltemac_llink_handle ${ethmac_handle}]
				set sdma [xget_sw_parameter_handle ${llink_handle} C_SDMA_CTRL_BASEADDR]
				if {[llength ${sdma}]} {
					debug info "      SDMA Mode"
					set bus_type [get_lltemac_llink_bus_type ${ethmac_handle}]
					set llink_name [get_lltemac_llink_name ${ethmac_handle}]
					debug info "      ${bus_type} <--> ${llink_name}"
				} else {
					set fifo [xget_sw_parameter_handle ${llink_handle} C_BASEADDR]
					if {[llength ${fifo}]} {
						debug info "      FIFO Mode"
						set bus_type [get_lltemac_llink_bus_type ${ethmac_handle}]
						set llink_fifo [xget_hw_name ${llink_handle}]
						debug info "      ${bus_type} <--> ${llink_fifo}"
					} else {
						error "ERROR: Your xps_ll_temac is not connected properly."
					}
				}
			}
			default {
				debug info "INFO: Ethernet (LITE) specified."
			}
		}
	}
}

#
# Fusion of all related function calls
#
namespace export put_pkg_cfg
proc put_pkg_cfg {pkg fh osh} {
	variable put_cfg_procs
	if {[array name put_cfg_procs ${pkg}] == ${pkg}} {
		if {[put_processor_cfg ${pkg} ${fh}]} {
			if {[put_intctrl_cfg ${pkg} ${fh}]} {
				foreach pr $put_cfg_procs($pkg) {
					${pr} ${pkg} ${fh} ${osh}
				}
			} else {
				debug info "put_intctrl_cfg() ERROR --> BREAK"
			}
		} else {
			debug info "put_processor_cfg() ERROR --> BREAK"
		}
	} else {
		error "ERROR: Wrong TPOS library configuration for module: ${pkg}"
	}
}

#
# CPU
#
namespace export put_processor_cfg
proc put_processor_cfg {pkg fh} {
	set hwproc_handle [get_hwproc_handle]
	set ft [get_file_type ${fh}]
	switch ${ft} {
		"ch"   { return [put_processor_cfg_ch ${pkg} ${fh} ${hwproc_handle}] }
		"mk"   { return [put_processor_cfg_mk ${pkg} ${fh} ${hwproc_handle}] }
		"kc24" { return [put_processor_cfg_ch [format "%s-24" ${pkg}] ${fh} ${hwproc_handle}] }
		"kc26" { return [put_processor_cfg_ch [format "%s-26" ${pkg}] ${fh} ${hwproc_handle}] }
		default {
			error "ERROR: This type of file is not supported yet: ${ft}"
		}
	}
	return 1
}

proc put_processor_cfg_ch {pkg fh hh} {
	set proctype [xget_value ${hh} "OPTION" "IPNAME"]
	switch ${proctype} {
		"microblaze" {
			switch ${pkg} {
				"fsboot" {
					set HWPROC_STR [xget_hw_parameter_value ${hh} INSTANCE]
					set HWPROC_STR [string map {_ ""} [string toupper ${HWPROC_STR}]]
					set defpre_hwproc CONFIG_XILINX_${HWPROC_STR}
					array set define {
						CLK			CONFIG_XILINX_CPU_CLOCK_FREQ
					}
				}
				"xlboot" {
					set defpre_hwproc ""
					array set define {
						FAMILY			XLB_MB_FAMILY
						HW_VER			XLB_MB_HW_VER
					}
				}
				"uboot" {
					set defpre_hwproc ""
					#	CACHE_BYTE_SIZE		XILINX_CACHE_BYTE_SIZE
					#	ICACHE_BASEADDR		XILINX_ICACHE_BASEADDR
					#	ICACHE_HIGHADDR		XILINX_ICACHE_HIGHADDR
					#	DCACHE_BASEADDR		XILINX_DCACHE_BASEADDR
					#	DCACHE_HIGHADDR		XILINX_DCACHE_HIGHADDR
					#	FAMILY			XILINX_FAMILY
					array set define {
						CLK			XILINX_CLOCK_FREQ
						USE_MSR_INSTR		XILINX_USE_MSR_INSTR
						FSL_LINKS		XILINX_FSL_NUMBER
						USE_ICACHE		XILINX_USE_ICACHE
						USE_DCACHE		XILINX_USE_DCACHE
						DCACHE_BYTE_SIZE	XILINX_DCACHE_BYTE_SIZE
						PVR			XILINX_PVR
					}
				}
				"linux-24" {
					set HWPROC_STR [xget_hw_parameter_value ${hh} INSTANCE]
					set HWPROC_STR [string map {_ ""} [string toupper ${HWPROC_STR}]]
					set defpre_hwproc XILINX_${HWPROC_STR}
					array set define {
						CLK			CONFIG_XILINX_CPU_CLOCK_FREQ
					}
				}
				"linux-26" {
					set defpre_hwproc ""
					#	INSTANCE		XILINX_MICROBLAZE0_INSTANCE
					#	_d_INSTANCE		"Core instance name"
					array set define {
						FAMILY			XILINX_MICROBLAZE0_FAMILY
						_d_FAMILY		"Targetted FPGA family"
						USE_MSR_INSTR		XILINX_MICROBLAZE0_USE_MSR_INSTR
						_d_USE_MSR_INSTR	"USE_MSR_INSTR range (0:1)"
						USE_PCMP_INSTR		XILINX_MICROBLAZE0_USE_PCMP_INSTR
						_d_USE_PCMP_INSTR	"USE_PCMP_INSTR range (0:1)"
						USE_BARREL		XILINX_MICROBLAZE0_USE_BARREL
						_d_USE_BARREL		"USE_BARREL range (0:1)"
						USE_DIV			XILINX_MICROBLAZE0_USE_DIV
						_d_USE_DIV		"USE_DIV range (0:1)"
						USE_HW_MUL		XILINX_MICROBLAZE0_USE_HW_MUL
						_d_USE_HW_MUL		"USE_HW_MUL values (0=NONE, 1=MUL32, 2=MUL64)"
						USE_FPU			XILINX_MICROBLAZE0_USE_FPU
						_d_USE_FPU		"USE_FPU values (0=NONE, 1=BASIC, 2=EXTENDED)"
						HW_VER			XILINX_MICROBLAZE0_HW_VER
						_d_HW_VER		"Core version number"
					}
				}
				default {
					set defpre_hwproc ""
					array set define {}
				}
			}

			# fast exit without any error if define array is empty 
			if {![array size define] && ![llength ${defpre_hwproc}]} { return 1 }

			# System Clock Frequency (if need)
			set arg_name CLK
			if {[array name define ${arg_name}] == ${arg_name}} {
				put_info ${fh} "System Clock Frequency"
				set des_name [format "_d_${arg_name}"]
				if {[array name define ${des_name}] == ${des_name}} {
					put_cfg_int ${fh} $define($arg_name) [get_clock_val ${hh}] $define($des_name)
				} else {
					put_cfg_int ${fh} $define($arg_name) [get_clock_val ${hh}]
				}
				put_blank_line ${fh}
			}

			# write only name of instance
			put_info ${fh} "Microblaze is [xget_hw_parameter_value ${hh} INSTANCE]"

			set args [xget_hw_parameter_handle ${hh} "*"]
			foreach arg ${args} {
				set arg_name [xget_value ${arg} "NAME"]
				set arg_name [string_trimleft_pat ${arg_name} C_]
				set arg_value [xget_value ${arg} "VALUE"]
				if {[array name define ${arg_name}] == ${arg_name}} {
					set des_name [format "_d_${arg_name}"]
					if {[array name define ${des_name}] == ${des_name}} {
						put_cfg ${fh} $define($arg_name) ${arg_value} $define($des_name)
					} else {
						put_cfg ${fh} $define($arg_name) ${arg_value}
					}
				} elseif {[llength ${defpre_hwproc}]} {
					put_cfg ${fh} ${defpre_hwproc}_${arg_name} ${arg_value} ${arg_name}
				}
			}
		}
		"ppc405" -
		"ppc405_virtex4" -
		"ppc440_virtex5" {
			put_info ${fh} "unsupported processor type $proctype"
			put_blank_line ${fh}
			return 0
		}
		default {
			error "ERROR: This type of CPU is not supported yet."
		}
	}

	put_blank_line ${fh}
	return 1
}

# Extraction fomr Xilinx documentation:
# -------------------------------------
# "MicroBlaze Processor Reference Guide",
#   Chapter 2: MicroBlaze Signal Interface Description
#              MicroBlaze Core Configurability (MPD Parameters)
#
# "Embedded System Tools Reference Manual",
#   Chapter 9: GNU Compiler Tools
#              MicroBlaze Compiler Usage and Options
#
# Different MPD parameters cause to different make options:
#   HW_VER		= X.YY.Z	-mcpu=vX.YY.Z
#
#   C_USE_HW_MUL	= 2	(64bit)	-mno-xl-soft-mul -mxl-multiply-high
#   C_USE_HW_MUL	= 1	(32bit)	-mno-xl-soft-mul
#   C_USE_HW_MUL	= 0		-mxl-soft-mul
#
#   C_USE_DIV		= 1	(32bit)	-mno-xl-soft-div
#   C_USE_DIV		= 0	(deflt)	-mxl-soft-div
#
#   C_USE_BARREL	= 1		-mxl-barrel-shift
#   C_USE_BARREL	= 0	(deflt)	-mno-xl-barrel-shift
#
#   C_USE_PCMP_INSTR	= 1		-mxl-pattern-compare
#   C_USE_PCMP_INSTR	= 0	(deflt)	-mno-xl-pattern-compare
#
#   C_USE_FPU		= 2		-mhard-float -mxl-float-convert -mxl-float-sqrt
#   C_USE_FPU		= 1		-mhard-float
#   C_USE_FPU		= 0	(deflt)	-msoft-float
#
proc put_processor_cfg_mk {pkg fh hh} {
	set proctype [xget_value ${hh} "OPTION" "IPNAME"]
	switch ${proctype} {
		"microblaze" {
			switch ${pkg} {
				"fsboot" -
				"xlboot" -
				"uboot"  { set cfvar "PLATFORM_CPPFLAGS" }
				default  { set cfvar "" }
			}

			array set cflags {
				HW_VER			-mcpu=v
				USE_HW_MUL_2 {
							-mno-xl-soft-mul
							-mxl-multiply-high
				}
				USE_HW_MUL_1		-mno-xl-soft-mul
				USE_DIV_1		-mno-xl-soft-div
				USE_BARREL_1		-mxl-barrel-shift
				USE_PCMP_INSTR_1	-mxl-pattern-compare
				USE_FPU_2 {
							-mhard-float
							-mxl-float-convert
							-mxl-float-sqrt
				}
				USE_FPU_1		-mhard-float
			}

			put_info ${fh} "Platform compiler flags"
			set args [xget_hw_parameter_handle ${hh} "*"]
			foreach arg ${args} {
				set arg_name [xget_value ${arg} "NAME"]
				set arg_name [string_trimleft_pat ${arg_name} C_]
				set arg_value [xget_value ${arg} "VALUE"]
				if {[string is integer ${arg_value}]} {
					set arg_name [format ${arg_name}_${arg_value}]
					if {[array name cflags ${arg_name}] == ${arg_name}} {
						foreach arg_value $cflags($arg_name) {
							put_var_append ${fh} ${cfvar} ${arg_value}
						}
					}
				} else {
					if {[array name cflags ${arg_name}] == ${arg_name}} {
						set arg_value [format $cflags($arg_name)${arg_value}]
						put_var_append ${fh} ${cfvar} ${arg_value}
					}
				}
			}
		}
		"ppc405" -
		"ppc405_virtex4" -
		"ppc440_virtex5" {
			put_info ${fh} "unsupported processor type $proctype"
			put_blank_line ${fh}
			return 0
		}
		default {
			error "ERROR: This type of CPU is not supported yet."
		}
	}

	put_blank_line ${fh}
	return 1
}

#
# Interrupt controller
#
namespace export put_intctrl_cfg
proc put_intctrl_cfg {pkg fh} {
	set intc_handle [get_intc_handle]
	if {[string match "" ${intc_handle}] || [string match -nocase "none" ${intc_handle}]} {
		debug warning "WARNING: Interrupt controller not specified."
		debug warning "         Please specify intc in projects MSS."
		put_info ${fh} "Interrupt controller not defined"
		put_blank_line ${fh}
		return 0
	}

	set ft [get_file_type ${fh}]
	switch ${ft} {
		"ch"   { return [put_intctrl_cfg_ch ${pkg} ${fh} ${intc_handle}] }
		"mk"   { return [put_intctrl_cfg_mk ${pkg} ${fh} ${intc_handle}] }
		"kc24" { return [put_intctrl_cfg_ch [format "%s-24" ${pkg}] ${fh} ${intc_handle}] }
		"kc26" { return [put_intctrl_cfg_ch [format "%s-26" ${pkg}] ${fh} ${intc_handle}] }
		default {
			error "ERROR: This type of file is not supported yet: ${ft}"
		}
	}
	return 1
}

proc put_intctrl_cfg_ch {pkg fh ih} {
	switch ${pkg} {
		"uboot" {
			set defpre_hwproc ""
			#	HIGHADDR		XILINX_INTC_HIGHADDR
			array set define {
				BASEADDR		XILINX_INTC_BASEADDR
				NUM_INTR_INPUTS		XILINX_INTC_NUM_INTR_INPUTS
			}
		}
		"linux-24" {
			set defpre_hwproc XILINX_INTC_0
			array set define {}
		}
		"fsboot" -
		"xlboot" -
		"linux-26" -
		default {
			set defpre_hwproc ""
			array set define {}
		}
	}

	# fast exit without any error if define array is empty 
	if {![array size define] && ![llength ${defpre_hwproc}]} { return 1 }

	put_info ${fh} "Interrupt controller is [xget_hw_name ${ih}]"

	# Interrupt controller address
	set args [xget_sw_parameter_handle ${ih} "*"]
	foreach arg ${args} {
		set arg_name [xget_value ${arg} "NAME"]
		set arg_name [string_trimleft_pat ${arg_name} C_]
		set arg_value [xget_value ${arg} "VALUE"]
		if {[array name define ${arg_name}] == ${arg_name}} {
			set des_name [format "_d_${arg_name}"]
			if {[array name define ${des_name}] == ${des_name}} {
				put_cfg ${fh} $define($arg_name) ${arg_value} $define($des_name)
			} else {
				put_cfg ${fh} $define($arg_name) ${arg_value}
			}
		} elseif {[llength ${defpre_hwproc}]} {
			put_cfg ${fh} ${defpre_hwproc}_${arg_name} ${arg_value} ${arg_name}
		}
	}

	# print out all connected interrupt sources
	foreach intc_sig [get_intc_signals ${ih}] {
		put_info ${fh} ${intc_sig}
	}

	put_blank_line ${fh}
	return 1
}

proc put_intctrl_cfg_mk {pkg fh ih} {
	#
	# nothing to do here (not yet)
	#
	return 1
}

#
# Timer
#
namespace export put_timer_cfg
proc put_timer_cfg {pkg fh osh} {
	set timer [xget_sw_parameter_value ${osh} "timer"]
	if {[string match "" ${timer}] || [string match -nocase "none" ${timer}]} {
		debug warning "WARNING: Timer not specified."
		debug warning "         Please specify timer in projects MSS."
		put_info ${fh} "Timer not defined"
		put_blank_line ${fh}
		return 0
	}

	# get timer handle per name from processor
	set timer_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] ${timer}]

	set ft [get_file_type ${fh}]
	switch ${ft} {
		"ch"   { return [put_timer_cfg_ch ${pkg} ${fh} ${osh} ${timer_handle}] }
		"mk"   { return [put_timer_cfg_mk ${pkg} ${fh} ${osh} ${timer_handle}] }
		"kc24" { return [put_timer_cfg_ch [format "%s-24" ${pkg}] ${fh} ${osh} ${timer_handle}] }
		"kc26" { return [put_timer_cfg_ch [format "%s-26" ${pkg}] ${fh} ${osh} ${timer_handle}] }
		default {
			error "ERROR: This type of file is not supported yet: ${ft}"
		}
	}
	return 1
}

proc put_timer_cfg_ch {pkg fh osh th} {
	switch ${pkg} {
		"fsboot" {
			set defpre_hwproc ""
			#	HIGHADDR	CONFIG_XILINX_TIMER_0_HIGHADDR
			#	Interrupt	CONFIG_XILINX_TIMER_0_IRQ
			array set define {
				BASEADDR	CONFIG_XILINX_TIMER_0_BASEADDR
			}
		}
		"uboot" {
			set defpre_hwproc ""
			#	HIGHADDR	XILINX_TIMER_HIGHADDR
			array set define {
				BASEADDR	XILINX_TIMER_BASEADDR
				Interrupt	XILINX_TIMER_IRQ
			}
		}
		"linux-24" {
			set defpre_hwproc XILINX_TIMER_0
			array set define {}
		}
		"xlboot" -
		"linux-26" -
		default {
			set defpre_hwproc ""
			array set define {}
		}
	}

	# fast exit without any error if define array is empty 
	if {![array size define] && ![llength ${defpre_hwproc}]} { return 1 }

	put_info ${fh} "Timer is [xget_hw_name ${th}]"

	# Timer pheriphery address
	set args [xget_sw_parameter_handle ${th} "*"]
	foreach arg ${args} {
		set arg_name [xget_value ${arg} "NAME"]
		set arg_name [string_trimleft_pat ${arg_name} C_]
		set arg_value [xget_value ${arg} "VALUE"]
		if {[array name define ${arg_name}] == ${arg_name}} {
			set des_name [format "_d_${arg_name}"]
			if {[array name define ${des_name}] == ${des_name}} {
				put_cfg ${fh} $define($arg_name) ${arg_value} $define($des_name)
			} else {
				put_cfg ${fh} $define($arg_name) ${arg_value}
			}
		} elseif {[llength ${defpre_hwproc}]} {
			put_cfg ${fh} ${defpre_hwproc}_${arg_name} ${arg_value} ${arg_name}
		}
	}

	# Interrupt source number
	set arg_name Interrupt
	set arg_value [get_intr ${th} ${arg_name}]
	if { ${arg_value} >= 0 } {
		if {[array name define ${arg_name}] == ${arg_name}} {
			set des_name [format "_d_${arg_name}"]
			if {[array name define ${des_name}] == ${des_name}} {
				put_cfg_int ${fh} $define($arg_name) ${arg_value} $define($des_name)
			} else {
				put_cfg_int ${fh} $define($arg_name) ${arg_value}
			}
		} elseif {[llength ${defpre_hwproc}]} {
			put_cfg ${fh} ${defpre_hwproc}_${arg_name} ${arg_value} ${arg_name}
		}
	}

	put_blank_line ${fh}
	return 1
}

proc put_timer_cfg_mk {pkg fh osh th} {
	#
	# nothing to do here (not yet)
	#
	return 1
}

#
# System memory
#
namespace export put_sysmem_cfg
proc put_sysmem_cfg {pkg fh osh} {
	set sysmem [xget_sw_parameter_value ${osh} "main_memory"]
	if {[string match "" ${sysmem}] || [string match -nocase "none" ${sysmem}]} {
		debug warning "WARNING: System memory not specified."
		debug warning "         Please specify main_memory in projects MSS."
		put_info ${fh} "System memory not defined"
		put_blank_line ${fh}
		return 0
	}

	# get sysmem handle per name from processor
	set sysmem_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] ${sysmem}]

	set ft [get_file_type ${fh}]
	switch ${ft} {
		"ch"   { return [put_sysmem_cfg_ch ${pkg} ${fh} ${osh} ${sysmem_handle}] }
		"mk"   { return [put_sysmem_cfg_mk ${pkg} ${fh} ${osh} ${sysmem_handle}] }
		"kc24" { return [put_sysmem_cfg_ch [format "%s-24" ${pkg}] ${fh} ${osh} ${sysmem_handle}] }
		"kc26" { return [put_sysmem_cfg_ch [format "%s-26" ${pkg}] ${fh} ${osh} ${sysmem_handle}] }
		default {
			error "ERROR: This type of file is not supported yet: ${ft}"
		}
	}
	return 1
}

proc put_sysmem_cfg_ch {pkg fh osh sh} {
	switch ${pkg} {
		"fsboot" {
			#	End		CONFIG_XILINX_ERAM_END
			array set define {
				Start		CONFIG_XILINX_ERAM_START
				Size		CONFIG_XILINX_ERAM_SIZE
			}
		}
		"xlboot" {
			#	End		XLB_RAM_END
			array set define {
				Start		XLB_RAM_START
				Size		XLB_RAM_SIZE
			}
		}
		"uboot" {
			#	End		XILINX_RAM_END
			array set define {
				Start		XILINX_RAM_START
				Size		XILINX_RAM_SIZE
			}
		}
		"linux-24" {
			array set define {
				Start		XILINX_ERAM_START
				Size		XILINX_ERAM_SIZE
			}
		}
		"linux-26" {
			array set define {
				Kernel		KERNEL_BASE_ADDR
				_d_Kernel	"Physical address where Linux Kernel is"
			}
		}
		default { array set define {} }
	}

	# fast exit without any error if define array is empty 
	if {![array size define]} { return 1 }

	put_info ${fh} "System memory is [xget_hw_name ${sh}]"

	# Naming different memory controller differently
	set sysmem_bank [xget_sw_parameter_value ${osh} "main_memory_bank"]
	if {[xget_hw_value ${sh}] == "mpmc"} {
		set parapre MPMC
	} else {
		set parapre [format MEM%i ${sysmem_bank}]
	}

	# System memory values
	set eram_base [get_addr_hex ${sh} [format C_%s_BASEADDR ${parapre}]]
	set eram_end [get_addr_hex ${sh} [format C_%s_HIGHADDR ${parapre}]]
	set eram_size [expr ${eram_end} - ${eram_base} + 1]
	set eram_size [format "0x%08x" ${eram_size}]

	# System memory address and size (if need)
	set arg_name Start
	if {[array name define ${arg_name}] == ${arg_name}} {
		set des_name [format "_d_${arg_name}"]
		if {[array name define ${des_name}] == ${des_name}} {
			put_cfg_int ${fh} $define($arg_name) ${eram_base} $define($des_name)
		} else {
			put_cfg_int ${fh} $define($arg_name) ${eram_base}
		}
	}
	set arg_name End
	if {[array name define ${arg_name}] == ${arg_name}} {
		set des_name [format "_d_${arg_name}"]
		if {[array name define ${des_name}] == ${des_name}} {
			put_cfg_int ${fh} $define($arg_name) ${eram_end} $define($des_name)
		} else {
			put_cfg_int ${fh} $define($arg_name) ${eram_end}
		}
	}
	set arg_name Size
	if {[array name define ${arg_name}] == ${arg_name}} {
		set des_name [format "_d_${arg_name}"]
		if {[array name define ${des_name}] == ${des_name}} {
			put_cfg_int ${fh} $define($arg_name) ${eram_size} $define($des_name)
		} else {
			put_cfg_int ${fh} $define($arg_name) ${eram_size}
		}
	}

	# Kernel base address (if need)
	set arg_name Kernel
	if {[array name define ${arg_name}] == ${arg_name}} {
		set des_name [format "_d_${arg_name}"]
		if {[array name define ${des_name}] == ${des_name}} {
			put_cfg_int ${fh} $define($arg_name) ${eram_base} $define($des_name)
		} else {
			put_cfg_int ${fh} $define($arg_name) ${eram_base}
		}
	}

	put_blank_line ${fh}
	return 1
}

proc put_sysmem_cfg_mk {pkg fh osh sh} {
	switch ${pkg} {
		# nothing to do for fsboot/xlboot
		"fsboot" -
		"xlboot" {
			return 1
		}
	}

	# Naming different memory controller differently
	set sysmem_bank [xget_sw_parameter_value ${osh} "main_memory_bank"]
	if {[xget_hw_value ${sh}] == "mpmc"} {
		set parapre MPMC
	} else {
		set parapre [format MEM%i ${sysmem_bank}]
	}

	# System memory values
	set eram_base [get_addr_hex ${sh} [format C_%s_BASEADDR ${parapre}]]
	set eram_end [get_addr_hex ${sh} [format C_%s_HIGHADDR ${parapre}]]

	set text_base [get_addr_hex ${osh} "uboot_position"]
	if {${text_base} == 0} {
		if {[llength ${eram_end}]} {
			# calulation of last 1MB
			set eram_boot [expr ${eram_end} - 0x100000 + 1]
			set eram_boot [format "0x%08x" ${eram_boot}]
			put_info ${fh} "Automatic U-Boot position at ${eram_boot}"
			put_cfg ${fh} "TEXT_BASE" ${eram_boot}
		} else {
			error "ERROR: Main memory is not defined."
		}
	} else {
		if {${eram_base} < ${text_base} && ${eram_end} > ${text_base}} {
			put_info ${fh} "U-Boot position at ${text_base}"
			put_cfg ${fh} "TEXT_BASE" ${text_base}
		} else {
			error "ERROR: U-Boot position is out of range: ${eram_base} - ${eram_end}"
		}
	}

	put_blank_line ${fh}
	return 1
}

#
# NOR Flash memory
#
namespace export put_normem_cfg
proc put_normem_cfg {pkg fh osh} {
	set normem [xget_sw_parameter_value ${osh} "flash_memory"]
	if {[string match "" ${normem}] || [string match -nocase "none" ${normem}]} {
		debug warning "WARNING: NOR Flash memory not specified."
		debug warning "         Please specify flash_memory in projects MSS."
		put_info ${fh} "NOR Flash memory not defined"
		put_blank_line ${fh}
		return 0
	}

	# get normem handle per name from processor
	set normem_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] ${normem}]

	set ft [get_file_type ${fh}]
	switch ${ft} {
		"ch"   { return [put_normem_cfg_ch ${pkg} ${fh} ${osh} ${normem_handle}] }
		"mk"   { return [put_normem_cfg_mk ${pkg} ${fh} ${osh} ${normem_handle}] }
		"kc24" { return [put_normem_cfg_ch [format "%s-24" ${pkg}] ${fh} ${osh} ${normem_handle}] }
		"kc26" { return [put_normem_cfg_ch [format "%s-26" ${pkg}] ${fh} ${osh} ${normem_handle}] }
		default {
			error "ERROR: This type of file is not supported yet: ${ft}"
		}
	}
	return 1
}

proc put_normem_cfg_ch {pkg fh osh nh} {
	switch ${pkg} {
		"fsboot" {
			#	End		CONFIG_XILINX_FLASH_END
			array set define {
				Start		CONFIG_XILINX_FLASH_START
				Size		CONFIG_XILINX_FLASH_SIZE
				SPIStart	CONFIG_XILINX_SPI_FLASH_BASEADDR
				SPIClock	CONFIG_XILINX_SPI_FLASH_MAX_FREQ
				SPICS		CONFIG_XILINX_SPI_FLASH_CS
			}
		}
		"xlboot" {
			#	End		XLB_FLASH_END
			array set define {
				Start		XLB_FLASH_START
				Size		XLB_FLASH_SIZE
			}
		}
		"uboot" {
			#	End		XILINX_FLASH_END
			array set define {
				Start		XILINX_FLASH_START
				Size		XILINX_FLASH_SIZE
				SPIStart	XILINX_SPI_FLASH_BASEADDR
				SPIClock	XILINX_SPI_FLASH_MAX_FREQ
				SPICS		XILINX_SPI_FLASH_CS
			}
		}
		"linux-24" {
			array set define {
				Start		XILINX_FLASH_START
				Size		XILINX_FLASH_SIZE
			}
		}
		"linux-26" -
		default { array set define {} }
	}

	# fast exit without any error if define array is empty 
	if {![array size define]} { return 1 }

	put_info ${fh} "NOR Flash memory is [xget_hw_name ${nh}]"

	# Handle different FLASHs differently
	set normem_bank [xget_sw_parameter_value ${osh} "flash_memory_bank"]
	set flash_type [xget_hw_value ${nh}]
	switch -exact ${flash_type} {
		"xps_spi" {
			# Serial SPI Flash
			set flash_base [get_addr_hex ${nh} C_BASEADDR]
			set flash_sys_clk [get_clock_frequency ${nh} SPLB_CLK]
			set flash_sck_ratio [xget_sw_parameter_value ${nh} C_SCK_RATIO]
			set flash_clk [expr { ${flash_sys_clk} / ${flash_sck_ratio} }]

			# SPI Flash memory address and size (if need)
			set arg_name SPIStart
			if {[array name define ${arg_name}] == ${arg_name}} {
				set des_name [format "_d_${arg_name}"]
				if {[array name define ${des_name}] == ${des_name}} {
					put_cfg_int ${fh} $define($arg_name) ${flash_base} $define($des_name)
				} else {
					put_cfg_int ${fh} $define($arg_name) ${flash_base}
				}
			}
			set arg_name SPIClock
			if {[array name define ${arg_name}] == ${arg_name}} {
				set des_name [format "_d_${arg_name}"]
				if {[array name define ${des_name}] == ${des_name}} {
					put_cfg_int ${fh} $define($arg_name) ${flash_clk} $define($des_name)
				} else {
					put_cfg_int ${fh} $define($arg_name) ${flash_clk}
				}
			}
			set arg_name SPICS
			if {[array name define ${arg_name}] == ${arg_name}} {
				set des_name [format "_d_${arg_name}"]
				if {[array name define ${des_name}] == ${des_name}} {
					put_cfg_int ${fh} $define($arg_name) ${normem_bank} $define($des_name)
				} else {
					put_cfg_int ${fh} $define($arg_name) ${normem_bank}
				}
			}
		}
		default {
			# Parallel Flash
			set parapre [format C_MEM%i ${normem_bank}]
			set flash_base [get_addr_hex ${nh} [format %s_BASEADDR ${parapre}]]
			set flash_end [get_addr_hex ${nh} [format %s_HIGHADDR ${parapre}]]
			set flash_size [format "0x%08x" [expr ${flash_end} - ${flash_base} + 1]]

			# Parallel Flash memory address and size (if need)
			set arg_name Start
			if {[array name define ${arg_name}] == ${arg_name}} {
				set des_name [format "_d_${arg_name}"]
				if {[array name define ${des_name}] == ${des_name}} {
					put_cfg_int ${fh} $define($arg_name) ${flash_base} $define($des_name)
				} else {
					put_cfg_int ${fh} $define($arg_name) ${flash_base}
				}
			}
			set arg_name End
			if {[array name define ${arg_name}] == ${arg_name}} {
				set des_name [format "_d_${arg_name}"]
				if {[array name define ${des_name}] == ${des_name}} {
					put_cfg_int ${fh} $define($arg_name) ${flash_end} $define($des_name)
				} else {
					put_cfg_int ${fh} $define($arg_name) ${flash_end}
				}
			}
			set arg_name Size
			if {[array name define ${arg_name}] == ${arg_name}} {
				set des_name [format "_d_${arg_name}"]
				if {[array name define ${des_name}] == ${des_name}} {
					put_cfg_int ${fh} $define($arg_name) ${flash_size} $define($des_name)
				} else {
					put_cfg_int ${fh} $define($arg_name) ${flash_size}
				}
			}
		}
	}

	put_blank_line ${fh}
	return 1
}

proc put_normem_cfg_mk {pkg fh osh nh} {
	#
	# nothing to do here (not yet)
	#
	return 1
}

#
# UART
#
namespace export put_uart_cfg
proc put_uart_cfg {pkg fh osh} {
	set uart [xget_sw_parameter_value ${osh} "stdout"]
	if {[string match "" ${uart}] || [string match -nocase "none" ${uart}]} {
		put_info ${fh} "Uart controller not defined"
		put_blank_line ${fh}
		return 0
	}

	# get uart handle per name from processor
	set uart_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] ${uart}]

	set ft [get_file_type ${fh}]
	switch ${ft} {
		"ch" { return [put_uart_cfg_ch ${pkg} ${fh} ${osh} ${uart_handle}] }
		"mk" { return [put_uart_cfg_mk ${pkg} ${fh} ${osh} ${uart_handle}] }
		default {
			error "ERROR: This type of file is not supported yet: ${ft}"
		}
	}
	return 1
}

proc put_uart_cfg_ch {pkg fh osh uh} {
	# Handle different UARTs differently
	set uart_type [xget_hw_value ${uh}]
	switch -exact ${uart_type} {
		"opb_uartlite" -
		"xps_uartlite" -
		"opb_mdm" -
		"xps_mdm" {
			return [put_uartlite_cfg ${pkg} ${fh} ${uh}]
		}
		"opb_uart16550" -
		"xps_uart16550" {
			return [put_uart16550_cfg ${pkg} ${fh} ${uh}]
		}
		default {
			error "ERROR: Unsupported type of console - ${uart_type}"
		}
	}
}

proc put_uart_cfg_mk {pkg fh osh uh} {
	#
	# nothing to do here (not yet)
	#
	return 1
}

proc put_uartlite_cfg {pkg fh uh} {
	switch ${pkg} {
		"fsboot" {
			#	HIGHADDR	CONFIG_STDINOUT_HIGHADDR
			#	BAUDRATE	CONFIG_UARTLITE_BAUDRATE
			#	Interrupt	CONFIG_UARTLITE_IRQ
			array set define {
				Enable		CONFIG_UARTLITE
				BASEADDR	CONFIG_STDINOUT_BASEADDR
			}
		}
		"xlboot" {
			#	HIGHADDR	XLB_STDIO_HIGHADDR
			#	BAUDRATE	XLB_UARTLITE_BAUDRATE
			#	Interrupt	XLB_UARTLITE_IRQ
			array set define {
				Enable		XLB_UARTLITE
				BASEADDR	XLB_STDIO_BASEADDR
			}
		}
		"uboot" {
			#	HIGHADDR	XILINX_UARTLITE_HIGHADDR
			#	Interrupt	XILINX_UARTLITE_IRQ
			array set define {
				Enable		XILINX_UARTLITE
				BASEADDR	XILINX_UARTLITE_BASEADDR
				BAUDRATE	XILINX_UARTLITE_BAUDRATE
			}
		}
		default { array set define {} }
	}

	# fast exit without any error if define array is empty 
	if {![array size define]} { return 1 }

	put_info ${fh} "Uart controller UARTLITE is [xget_hw_name ${uh}]"
	set arg_name Enable
	if {[array name define ${arg_name}] == ${arg_name}} {
		put_cfg_ena ${fh} $define($arg_name)
	}

	# Uart pheriphery values
	set args [xget_sw_parameter_handle ${uh} "*"]
	foreach arg ${args} {
		set arg_name [xget_value ${arg} "NAME"]
		set arg_name [string_trimleft_pat ${arg_name} C_]
		set arg_value [xget_value ${arg} "VALUE"]
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg ${fh} $define($arg_name) ${arg_value}
		}
	}

	# Interrupt source number
	set arg_name Interrupt
	set arg_value [get_intr ${uh} ${arg_name}]
	if { ${arg_value} >= 0 } {
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg_int ${fh} $define($arg_name) ${arg_value}
		}
	}

	put_blank_line ${fh}
	return 1
}

proc put_uart16550_cfg {pkg fh uh} {
	switch ${pkg} {
		"fsboot" {
			#	HIGHADDR	CONFIG_STDINOUT_HIGHADDR
			#	IP2INTC_Irpt	CONFIG_XILINX_UART16550_0_IRQ
			array set define {
				Enable		CONFIG_UART16550
				BASEADDR	CONFIG_STDINOUT_BASEADDR
				Clock		CONFIG_XILINX_UART16550_0_CLOCK_HZ
			}
		}
		"xlboot" {
			#	HIGHADDR	XLB_STDIO_HIGHADDR
			#	IP2INTC_Irpt	XLB_XILINX_UART16550_0_IRQ
			array set define {
				Enable		XLB_UART16550
				BASEADDR	XLB_STDIO_BASEADDR
				Clock		XLB_XILINX_UART16550_0_CLOCK_HZ
			}
		}
		"uboot" {
			#	HIGHADDR	XILINX_UART16550_HIGHADDR
			#	IP2INTC_Irpt	XILINX_UART16550_IRQ
			array set define {
				Enable		XILINX_UART16550
				BASEADDR	XILINX_UART16550_BASEADDR
				Clock		XILINX_UART16550_CLOCK_HZ
			}
		}
		default { array set define {} }
	}

	# fast exit without any error if define array is empty 
	if {![array size define]} { return 1 }

	put_info ${fh} "Uart controller UART16550 is [xget_hw_name ${uh}]"
	set arg_name Enable
	if {[array name define ${arg_name}] == ${arg_name}} {
		put_cfg_ena ${fh} $define($arg_name)
	}

	# Uart pheriphery values
	set args [xget_sw_parameter_handle ${uh} "*"]
	foreach arg ${args} {
		set arg_name [xget_value ${arg} "NAME"]
		set arg_name [string_trimleft_pat ${arg_name} C_]
		set arg_value [xget_value ${arg} "VALUE"]
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg ${fh} $define($arg_name) ${arg_value}
		}
	}

	# Uart clocking value
	set arg_name Clock
	if {[array name define ${arg_name}] == ${arg_name}} {
		put_cfg_int ${fh} $define($arg_name) [get_clock_val ${uh}]
	}

	# Interrupt source number
	set arg_name IP2INTC_Irpt
	set arg_value [get_intr ${uh} ${arg_name}]
	if { ${arg_value} >= 0 } {
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg_int ${fh} $define($arg_name) ${arg_value}
		}
	}

	put_blank_line ${fh}
	return 1
}

#
# I2C controller
#
namespace export put_iic_cfg
proc put_iic_cfg {pkg fh osh} {
	set iic [xget_sw_parameter_value ${osh} "iic"]
	if {[string match "" ${iic}] || [string match -nocase "none" ${iic}]} {
		put_info ${fh} "I2C controller not defined"
		put_blank_line ${fh}
		return 0
	}

	# get iic handle per name from processor
	set iic_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] ${iic}]

	set ft [get_file_type ${fh}]
	switch ${ft} {
		"ch" { return [put_iic_cfg_ch ${pkg} ${fh} ${osh} ${iic_handle}] }
		"mk" { return [put_iic_cfg_mk ${pkg} ${fh} ${osh} ${iic_handle}] }
		default {
			error "ERROR: This type of file is not supported yet: ${ft}"
		}
	}
	return 1
}

proc put_iic_cfg_ch {pkg fh osh ih} {
	switch ${pkg} {
		"fsboot" {
			#	BASEADDR	CONFIG_XILINX_IIC_BASEADDR
			#	HIGHADDR	CONFIG_XILINX_IIC_HIGHADDR
			#	IIC_FREQ	CONFIG_XILINX_IIC_FREQ
			#	TEN_BIT_ADR	CONFIG_XILINX_IIC_BIT
			#	Interrupt	CONFIG_XILINX_IIC_IRQ
			array set define {
			}
		}
		"uboot" {
			#	HIGHADDR	XILINX_IIC_0_HIGHADDR
			#	Interrupt	XILINX_IIC_0_IRQ
			array set define {
				BASEADDR	XILINX_IIC_0_BASEADDR
				IIC_FREQ	XILINX_IIC_0_FREQ
				TEN_BIT_ADR	XILINX_IIC_0_BIT
			}
		}
		default { array set define {} }
	}

	# fast exit without any error if define array is empty 
	if {![array size define]} { return 1 }

	put_info ${fh} "I2C controller is [xget_hw_name ${ih}]"

	# I2C pheriphery values
	set args [xget_sw_parameter_handle ${ih} "*"]
	foreach arg ${args} {
		set arg_name [xget_value ${arg} "NAME"]
		set arg_name [string_trimleft_pat ${arg_name} C_]
		set arg_value [xget_value ${arg} "VALUE"]
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg ${fh} $define($arg_name) ${arg_value}
		}
	}

	# Interrupt source number
	set arg_name Interrupt
	set arg_value [get_intr ${ih} ${arg_name}]
	if { ${arg_value} >= 0 } {
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg_int ${fh} $define($arg_name) ${arg_value}
		}
	}

	put_blank_line ${fh}
	return 1
}

proc put_iic_cfg_mk {pkg fh osh ih} {
	#
	# nothing to do here (not yet)
	#
	return 1
}

#
# GPIO controller
#
namespace export put_gpio_cfg
proc put_gpio_cfg {pkg fh osh} {
	set gpio [xget_sw_parameter_value ${osh} "gpio"]
	if {[string match "" ${gpio}] || [string match -nocase "none" ${gpio}]} {
		put_info ${fh} "GPIO controller not defined"
		put_blank_line ${fh}
		return 0
	}

	# get gpio handle per name from processor
	set gpio_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] ${gpio}]

	set ft [get_file_type ${fh}]
	switch ${ft} {
		"ch" { return [put_gpio_cfg_ch ${pkg} ${fh} ${osh} ${gpio_handle}] }
		"mk" { return [put_gpio_cfg_mk ${pkg} ${fh} ${osh} ${gpio_handle}] }
		default {
			error "ERROR: This type of file is not supported yet: ${ft}"
		}
	}
	return 1
}

proc put_gpio_cfg_ch {pkg fh osh gh} {
	switch ${pkg} {
		"fsboot" {
			#	BASEADDR	CONFIG_XILINX_GPIO_BASEADDR
			#	HIGHADDR	CONFIG_XILINX_GPIO_HIGHADDR
			#	IP2INTC_Irpt	CONFIG_XILINX_GPIO_IRQ
			array set define {
			}
		}
		"uboot" {
			#	HIGHADDR	XILINX_GPIO_HIGHADDR
			#	IP2INTC_Irpt	XILINX_GPIO_IRQ
			array set define {
				BASEADDR	XILINX_GPIO_BASEADDR
			}
		}
		default { array set define {} }
	}

	# fast exit without any error if define array is empty 
	if {![array size define]} { return 1 }

	put_info ${fh} "GPIO controller is [xget_hw_name ${gh}]"

	# GPIO controller values
	set args [xget_sw_parameter_handle ${gh} "*"]
	foreach arg ${args} {
		set arg_name [xget_value ${arg} "NAME"]
		set arg_name [string_trimleft_pat ${arg_name} C_]
		set arg_value [xget_value ${arg} "VALUE"]
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg ${fh} $define($arg_name) ${arg_value}
		}
	}

	# Interrupt source number
	set arg_name IP2INTC_Irpt
	set arg_value [get_intr ${gh} ${arg_name}]
	if { ${arg_value} >= 0 } {
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg_int ${fh} $define($arg_name) ${arg_value}
		}
	}

	put_blank_line ${fh}
	return 1
}

proc put_gpio_cfg_mk {pkg fh osh gh} {
	#
	# nothing to do here (not yet)
	#
	return 1
}

#
# Sysace CF controller
#
namespace export put_sysace_cfg
proc put_sysace_cfg {pkg fh osh} {
	set sysace [xget_sw_parameter_value ${osh} "sysace"]
	if {[string match "" ${sysace}] || [string match -nocase "none" ${sysace}]} {
		put_info ${fh} "Sysace CF controller not defined"
		put_blank_line ${fh}
		return 0
	}

	# get sysace handle per name from processor
	set sysace_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] ${sysace}]

	set ft [get_file_type ${fh}]
	switch ${ft} {
		"ch" { return [put_sysace_cfg_ch ${pkg} ${fh} ${osh} ${sysace_handle}] }
		"mk" { return [put_sysace_cfg_mk ${pkg} ${fh} ${osh} ${sysace_handle}] }
		default {
			error "ERROR: This type of file is not supported yet: ${ft}"
		}
	}
	return 1
}

proc put_sysace_cfg_ch {pkg fh osh sh} {
	switch ${pkg} {
		"fsboot" {
			#	BASEADDR	CONFIG_XILINX_SYSACE_BASEADDR
			#	HIGHADDR	CONFIG_XILINX_SYSACE_HIGHADDR
			#	MEM_WIDTH	CONFIG_XILINX_SYSACE_MEM_WIDTH
			#	Interrupt	CONFIG_XILINX_SYSACE_IRQ
			array set define {
			}
		}
		"uboot" {
			#	HIGHADDR	XILINX_SYSACE_HIGHADDR
			#	Interrupt	XILINX_SYSACE_IRQ
			array set define {
				BASEADDR	XILINX_SYSACE_BASEADDR
				MEM_WIDTH	XILINX_SYSACE_MEM_WIDTH
			}
		}
		default { array set define {} }
	}

	# fast exit without any error if define array is empty 
	if {![array size define]} { return 1 }

	put_info ${fh} "Sysace CF controller is [xget_hw_name ${sh}]"

	# Sysace CF controller values
	set args [xget_sw_parameter_handle ${sh} "*"]
	foreach arg ${args} {
		set arg_name [xget_value ${arg} "NAME"]
		set arg_name [string_trimleft_pat ${arg_name} C_]
		set arg_value [xget_value ${arg} "VALUE"]
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg ${fh} $define($arg_name) ${arg_value}
		}
	}

	# Interrupt source number
	set arg_name Interrupt
	set arg_value [get_intr ${sh} ${arg_name}]
	if { ${arg_value} >= 0 } {
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg_int ${fh} $define($arg_name) ${arg_value}
		}
	}

	put_blank_line ${fh}
	return 1
}

proc put_sysace_cfg_mk {pkg fh osh sh} {
	#
	# nothing to do here (not yet)
	#
	return 1
}

#
# Ethernet
#
namespace export put_ethmac_cfg
proc put_ethmac_cfg {pkg fh osh} {
	set ethmac [xget_sw_parameter_value ${osh} "ethernet"]
	if {[string match "" ${ethmac}] || [string match -nocase "none" ${ethmac}]} {
		put_info ${fh} "Ethernet MAC not defined"
		put_blank_line ${fh}
		return 0
	}

	# get ethmac handle per name from processor
	set ethmac_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] ${ethmac}]

	set ft [get_file_type ${fh}]
	switch ${ft} {
		"ch" { return [put_ethmac_cfg_ch ${pkg} ${fh} ${osh} ${ethmac_handle}] }
		"mk" { return [put_ethmac_cfg_mk ${pkg} ${fh} ${osh} ${ethmac_handle}] }
		default {
			error "ERROR: This type of file is not supported yet: ${ft}"
		}
	}
	return 1
}

proc put_ethmac_cfg_ch {pkg fh osh eh} {
	# Handle different MACs differently
	set ethmac_type [xget_hw_value ${eh}]
	switch -exact ${ethmac_type} {
		"opb_ethernet" -
		"xps_ethernet" {
			return [put_ethernet_cfg ${pkg} ${fh} ${eh}]
		}
		"opb_ethernetlite" -
		"xps_ethernetlite" {
			return [put_ethernetlite_cfg ${pkg} ${fh} ${eh}]
		}
		"xps_ll_temac" {
			return [put_lltemac_cfg ${pkg} ${fh} ${eh}]
		}
		default {
			error "ERROR: Unsupported type of Ethernet MAC - ${ethmac_type}"
		}
	}
}

proc put_ethmac_cfg_mk {pkg fh osh th} {
	#
	# nothing to do here (not yet)
	#
	return 1
}

proc put_ethernet_cfg {pkg fh eh} {
	switch ${pkg} {
		"fsboot" {
			#	Enable		CONFIG_EMAC
			#	BASEADDR	CONFIG_EMAC_BASEADDR
			#	HIGHADDR	CONFIG_EMAC_HIGHADDR
			#	MII_EXIST	CONFIG_EMAC_MII_EXIST
			#	DMA_PRESENT	CONFIG_EMAC_DMA_PRESENT
			#	HALF_DUPLEX_EXIST CONFIG_EMAC_HALF_DUPLEX_EXIST
			#	IP2INTC_Irpt	CONFIG_EMAC_IRQ
			array set define {
			}
		}
		"uboot" {
			#	HIGHADDR	XILINX_EMAC_HIGHADDR
			#	MII_EXIST	XILINX_EMAC_MII_EXIST
			#	DMA_PRESENT	XILINX_EMAC_DMA_PRESENT
			#	HALF_DUPLEX_EXIST XILINX_EMAC_HALF_DUPLEX_EXIST
			#	IP2INTC_Irpt	XILINX_EMAC_IRQ
			array set define {
				Enable		XILINX_EMAC
				BASEADDR	XILINX_EMAC_BASEADDR
			}
		}
		default { array set define {} }
	}

	# fast exit without any error if define array is empty 
	if {![array size define]} { return 1 }

	put_info ${fh} "Ethernet MAC controller EMAC is [xget_hw_name ${eh}]"
	set arg_name Enable
	if {[array name define ${arg_name}] == ${arg_name}} {
		put_cfg_ena ${fh} $define($arg_name)
	}

	# Ethernet MAC pheriphery values
	set args [xget_sw_parameter_handle ${eh} "*"]
	foreach arg ${args} {
		set arg_name [xget_value ${arg} "NAME"]
		set arg_name [string_trimleft_pat ${arg_name} C_]
		set arg_value [xget_value ${arg} "VALUE"]
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg ${fh} $define($arg_name) ${arg_value}
		}
	}

	# Interrupt source number
	set arg_name IP2INTC_Irpt
	set arg_value [get_intr ${eh} ${arg_name}]
	if { ${arg_value} >= 0 } {
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg_int ${fh} $define($arg_name) ${arg_value}
		}
	}

	put_blank_line ${fh}
	return 1
}

proc put_ethernetlite_cfg {pkg fh eh} {
	switch ${pkg} {
		"fsboot" {
			#	Enable		CONFIG_EMACLITE
			#	BASEADDR	CONFIG_EMACLITE_BASEADDR
			#	HIGHADDR	CONFIG_EMACLITE_HIGHADDR
			#	TX_PING_PONG	CONFIG_EMACLITE_TX_PING_PONG
			#	RX_PING_PONG	CONFIG_EMACLITE_RX_PING_PONG
			#	IP2INTC_Irpt	CONFIG_EMACLITE_IRQ
			array set define {
			}
		}
		"uboot" {
			#	HIGHADDR	XILINX_EMACLITE_HIGHADDR
			#	IP2INTC_Irpt	XILINX_EMACLITE_IRQ
			array set define {
				Enable		XILINX_EMACLITE
				BASEADDR	XILINX_EMACLITE_BASEADDR
				TX_PING_PONG	XILINX_EMACLITE_TX_PING_PONG
				RX_PING_PONG	XILINX_EMACLITE_RX_PING_PONG
			}
		}
		default { array set define {} }
	}

	# fast exit without any error if define array is empty 
	if {![array size define]} { return 1 }

	put_info ${fh} "Ethernet MAC controller EMACLITE is [xget_hw_name ${eh}]"
	set arg_name Enable
	if {[array name define ${arg_name}] == ${arg_name}} {
		put_cfg_ena ${fh} $define($arg_name)
	}

	# Ethernet MAC pheriphery values
	set args [xget_sw_parameter_handle ${eh} "*"]
	foreach arg ${args} {
		set arg_name [xget_value ${arg} "NAME"]
		set arg_name [string_trimleft_pat ${arg_name} C_]
		set arg_value [xget_value ${arg} "VALUE"]
		switch ${arg_name} {
			"TX_PING_PONG" -
			"RX_PING_PONG" {
				if { ${arg_value} != 1 } {
					continue
				}
			}
			default { }
		}
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg ${fh} $define($arg_name) ${arg_value}
		}
	}

	# Interrupt source number
	set arg_name IP2INTC_Irpt
	set arg_value [get_intr ${eh} ${arg_name}]
	if { ${arg_value} >= 0 } {
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg_int ${fh} $define($arg_name) ${arg_value}
		}
	}

	put_blank_line ${fh}
	return 1
}

proc put_lltemac_cfg {pkg fh eh} {
	switch ${pkg} {
		"fsboot" {
			#	Enable		CONFIG_LLTEMAC
			#	BASEADDR	CONFIG_LLTEMAC_BASEADDR
			#	HIGHADDR	CONFIG_LLTEMAC_HIGHADDR
			#	SDMA_BASEADDR	CONFIG_LLTEMAC_SDMA_CTRL_BASEADDR
			#	FIFO_BASEADDR	CONFIG_LLTEMAC_FIFO_BASEADDR
			#	TemacIntc0_Irpt	CONFIG_LLTEMAC_IRQ
			array set define {
			}
		}
		"uboot" {
			#	HIGHADDR	XILINX_LLTEMAC_HIGHADDR
			#	TemacIntc0_Irpt	XILINX_LLTEMAC_IRQ
			array set define {
				Enable		XILINX_LLTEMAC
				BASEADDR	XILINX_LLTEMAC_BASEADDR
				SDMA_BASEADDR	XILINX_LLTEMAC_SDMA_CTRL_BASEADDR
				FIFO_BASEADDR	XILINX_LLTEMAC_FIFO_BASEADDR
			}
		}
		default { array set define {} }
	}

	# fast exit without any error if define array is empty 
	if {![array size define]} { return 1 }

	put_info ${fh} "Ethernet MAC controller LLTEMAC is [xget_hw_name ${eh}]"
	set arg_name Enable
	if {[array name define ${arg_name}] == ${arg_name}} {
		put_cfg_ena ${fh} $define($arg_name)
	}

	# Ethernet MAC pheriphery values
	set args [xget_sw_parameter_handle ${eh} "*"]
	foreach arg ${args} {
		set arg_name [xget_value ${arg} "NAME"]
		set arg_name [string_trimleft_pat ${arg_name} C_]
		set arg_value [xget_value ${arg} "VALUE"]
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg ${fh} $define($arg_name) ${arg_value}
		}
	}

	# SDMA or FIFO pheriphery values
	set llink_handle [get_lltemac_llink_handle ${eh}]
	set sdma [xget_sw_parameter_handle ${llink_handle} C_SDMA_CTRL_BASEADDR]
	if {[llength ${sdma}]} {
		set llink_name [get_lltemac_llink_name ${eh}]
		set sdma_channel [string index "${llink_name}" [expr [string length ${llink_name}] - 1]]
		set sdma_name [xget_value ${sdma} "NAME"]
		set sdma_name [string_trimleft_pat ${sdma_name} C_]
		set sdma_value [xget_value ${sdma} "VALUE"]
		set sdma_value [expr ${sdma_value} + [expr ${sdma_channel} * 0x80]]
		set sdma_value [format "0x%08x" ${sdma_value}] 
		set arg_name SDMA_BASEADDR
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg ${fh} $define($arg_name) ${sdma_value}
		}
	} else {
		set fifo [xget_sw_parameter_handle ${llink_handle} C_BASEADDR]
		if {[llength ${fifo}]} {
			set fifo_name [xget_value ${fifo} "NAME"]
			set fifo_name [string_trimleft_pat ${fifo_name} C_]
			set fifo_value [xget_value ${fifo} "VALUE"]
			set arg_name FIFO_BASEADDR
			if {[array name define ${arg_name}] == ${arg_name}} {
				put_cfg ${fh} $define($arg_name) ${fifo_value}
			}
		} else {
			debug warning "WARNING: Your xps_ll_temac is not connected properly."
		}
	}

	# Interrupt source number
	set arg_name TemacIntc0_Irpt
	set arg_value [get_intr ${eh} ${arg_name}]
	if { ${arg_value} >= 0 } {
		if {[array name define ${arg_name}] == ${arg_name}} {
			put_cfg_int ${fh} $define($arg_name) ${arg_value}
		}
	}

	put_blank_line ${fh}
	return 1
}

#############################################################################
#   Data fetching functions
#
# Return the clock frequency attribute of the port of the given ip core.
proc get_clock_frequency {ip_handle portname} {
	set clk ""
	set clkhandle [xget_hw_port_handle $ip_handle $portname]
	if {[string compare -nocase $clkhandle ""] != 0} {
		set clk [xget_hw_subproperty_value $clkhandle "CLK_FREQ_HZ"]
	}
	return $clk
}

proc get_clock_val {hw_handle} {
	set ipname [xget_hw_name $hw_handle]
	set ports [xget_hw_port_handle $hw_handle "*"]
	foreach port $ports {
		set sigis [xget_hw_subproperty_value $port "SIGIS"]
		if {[string toupper $sigis] == "CLK"} {
			set portname [xget_hw_name $port]
			# EDK doesn't compute clocks for ports that aren't connected.
			set connected_port [xget_hw_port_value $hw_handle $portname]
			if {[llength $connected_port] != 0} {
				set frequency [get_clock_frequency $hw_handle $portname]
				return "$frequency"
			}
		}
	}
	error "ERROR: Can not find correct clock frequency for ${ipname}."
}

# Return the base address for given handle
proc get_addr_hex {handle name} {
	return [format "0x%08x" [get_value ${handle} ${name}]]
}

proc get_value {handle name} {
	set value [xget_sw_parameter_value "${handle}" "${name}"]
	if {![llength $value]} {
		error "ERROR: Request for undefined value [xget_hw_name ${handle}]:${name}"
	}
	return $value
}

#test for peripheral - if is correct setting system bus
proc test_buses {system_bus handle bus_type} {
	set bus [xget_handle ${handle} "BUS_INTERFACE" ${bus_type}]
	if { [llength ${bus}] == 0 } {
		return 1
	}
	set bus [xget_value ${bus} "VALUE"]
	if { ${bus} != ${system_bus}} {
		error "ERROR: Periphery ${handle} is connected to another system bus ${bus} ----"
		return 0
	} else {
		set name [xget_value ${handle} "NAME"]
		debug cpu "CPU: ${name} has correct system bus ${system_bus}"
	}
	return 1
}

# Get interrupt number
proc get_intr {per_handle port_name} {
	set intc_handle [get_intc_handle]
	set intc_signals [get_intc_signals ${intc_handle}]
	set port_handle [xget_hw_port_handle ${per_handle} "${port_name}"]
	if { [llength ${port_handle}] == 0 } {
		debug cpu "CPU: Can not fount interrupt for [xget_hw_name ${per_handle}]"
		set ports [xget_hw_port_handle ${per_handle} "*"]
		foreach port ${ports} {
			set portname [xget_hw_name ${port}]
			debug cpu "     port \"${port}\" is name \"${portname}\""
		}
		return -1
	}
	set interrupt_signal [xget_value ${port_handle} "VALUE"]
	set index [lsearch ${intc_signals} ${interrupt_signal}]
	if {${index} == -1} {
		return -1
	} else {
		# interrupt 0 is last in list.
		return [expr [llength ${intc_signals}] - ${index} - 1]
	}
}

proc get_intc_signals {intc_handle} {
	set signals [split [xget_hw_port_value ${intc_handle} "intr"] "&"]
	set intc_signals {}
	foreach signal ${signals} {
		lappend {intc_signals} [string trim ${signal}]
	}
	return ${intc_signals}
}

proc get_hwproc_handle {} {
	return [xget_handle [xget_libgen_proc_handle] "IPINST"]
}

proc get_intc_handle {} {
	# hangle to mhs file and get handle to interrupt port on CPU
	set hwproc_handle [get_hwproc_handle]
	set mhs_handle [xget_hw_parent_handle ${hwproc_handle}]
	set intr_port [xget_value ${hwproc_handle} "PORT" "Interrupt"]

	if { [llength ${intr_port}] == 0 } {
		debug cpu "CPU: CPU has no connection to Interrupt controller"
		return
	}

#	set sink_port [xget_hw_connected_ports_handle ${mhs_handle} ${intr_port} "sink"]
#	set sink_name [xget_hw_name ${sink_port}]

	# get source port periphery handle - on interrupt controller
	set source_port [xget_hw_connected_ports_handle ${mhs_handle} ${intr_port} "source"]
	set intc_handle [xget_hw_parent_handle ${source_port}]

	return ${intc_handle}
}

# system bus resolve: mb_opb, mb_plb
proc get_system_bus {} {
	set hwproc_handle [get_hwproc_handle]
	set busif_handle [xget_hw_busif_handle ${hwproc_handle} "DPLB"]
	if {[llength ${busif_handle}] != 0} {
		# Microblaze v7 has PLB.
		set dplb [xget_handle ${hwproc_handle} "BUS_INTERFACE" "DPLB"]
		set dplb [xget_value ${dplb} "VALUE"]
		set iplb [xget_handle ${hwproc_handle} "BUS_INTERFACE" "IPLB"]
		set iplb [xget_value ${iplb} "VALUE"]
		if { ${dplb} == ${iplb} } {
			debug cpu "CPU: System bus for instruction and data ${dplb}"
			return ${dplb}
		} else {
			error "ERROR: Different microblaze architecture - dual busses: ${iplb} ${dplb}"
		}
	} else {
		# Older microblazes have OPB.
		set dopb [xget_handle ${hwproc_handle} "BUS_INTERFACE" "DOPB"]
		set dopb [xget_value ${dopb} "VALUE"]
		set iopb [xget_handle ${hwproc_handle} "BUS_INTERFACE" "IOPB"]
		set iopb [xget_value ${iopb} "VALUE"]
		if { ${dopb} == ${iopb} } {
			debug cpu "CPU: System bus for instruction and data ${dopb}"
			# testing
#			set bus [xget_sw_parameter_value ${os_handle} "opb_v20"]
##			set bus_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] ${bus}]
##			set hodn [xget_sw_parameter_value ${bus_handle} C_EXT_RESET_HIGH]
#			debug cpu "CPU: fdf ${bus} fds"
#			set clk [xget_handle ${dopb} "PORT" "OPB_Clk"]
#			debug cpu "CPU: ${clk}"
#			set clk [xget_value ${clk} "VALUE"]
#			error "ERROR: ${clk}"
			# end testing
			return ${dopb}
		} else {
			error "ERROR: Different microblaze architecture - dual busses: ${iopb} ${dopb}"
		}
	}
}

proc get_lltemac_llink_bus_type {eh} {
	set mhs_handle [xget_hw_parent_handle ${eh}]
	set bus_handle [xget_handle ${eh} "BUS_INTERFACE" "LLINK0"]
	set bus_type [xget_hw_value ${bus_handle}]
	set slave_ips [xget_hw_connected_busifs_handle ${mhs_handle} ${bus_type} "INITIATOR"]
	if { ${bus_handle} != ${slave_ips} } {
		error "ERROR: Bus initiator (this slave) is not xps_ll_temac"
	}
	return ${bus_type}
}

proc get_lltemac_llink_bus {eh} {
	set mhs_handle [xget_hw_parent_handle ${eh}]
	set bus_type [get_lltemac_llink_bus_type ${eh}]
	return [xget_hw_connected_busifs_handle ${mhs_handle} ${bus_type} "TARGET"]
}

proc get_lltemac_llink_name {eh} {
	return [xget_hw_name [get_lltemac_llink_bus ${eh}]]
}

proc get_lltemac_llink_handle {eh} {
	return [xget_hw_parent_handle [get_lltemac_llink_bus ${eh}]]
}

#############################################################################
#   File output functions
#
# put_blank_line <file_handle>
proc put_blank_line {fh} {
	puts ${fh} ""
}

# put_info <file_handle> <information>
proc put_info {fh infstr} {
	debug info ${infstr}
	switch [get_file_type ${fh}] {
		ch { puts ${fh} "/* ${infstr} */" }
		mk { puts ${fh} "\# ${infstr}" }
		kc24 { puts ${fh} "\# ${infstr}" }
		kc26 {
			puts ${fh} "\# ${infstr}"
			puts ${fh} "comment \"${infstr}\""
			put_blank_line ${fh}
		}
		default {}
	}
}

# put_cfg <file_handle> <variable_name> <value> [<description>]
proc put_cfg {fh var val args} {
	if {[llength ${args}]} {
		set descr [lindex ${args} 0]
	} else {
		set descr ${var}
	}
	if {[string is integer ${val}]} {
		put_cfg_int ${fh} ${var} ${val} ${descr}
	} else {
		put_cfg_str ${fh} ${var} ${val} ${descr}
	}
}

# put_cfg_int <file_handle> <variable_name> <value> [<description>]
proc put_cfg_int {fh var val args} {
	debug jabber "${var} <-- ${val}"
	switch [get_file_type ${fh}] {
		ch { puts ${fh} [format "#define %-40s %s" ${var} ${val}] }
		mk { puts ${fh} [format "%-8s = %s" ${var} ${val}] }
		kc24 {
			if {[string match -nocase 0x* ${val}]} {
				puts ${fh} [format "define_hex CONFIG_%s %s" ${var} ${val}]
			} else {
				puts ${fh} [format "define_int CONFIG_%s %s" ${var} ${val}]
			}
		}
		kc26 {
			if {[llength ${args}]} {
				set descr [lindex ${args} 0]
			} else {
				set descr ${var}
			}
			if {[string match -nocase 0x* ${val}]} {
				puts ${fh} "config ${var}"
				puts ${fh} "\thex \"${descr}\""
				puts ${fh} "\tdefault ${val}"
			} else {
				puts ${fh} "config ${var}"
				puts ${fh} "\tint \"${descr}\""
				puts ${fh} "\tdefault ${val}"
			}
			put_blank_line ${fh}
		}
		default {}
	}
}

# put_cfg_str <file_handle> <variable_name> <value> [<description>]
proc put_cfg_str {fh var val args} {
	debug jabber "${var} <-- \"${val}\""
	switch [get_file_type ${fh}] {
		ch { puts ${fh} [format "#define %-40s \"%s\"" ${var} ${val}] }
		mk { puts ${fh} [format "%-8s = \"%s\"" ${var} ${val}] }
		kc24 {
			puts ${fh} [format "define_string CONFIG_%s %s" ${var} ${val}]
		}
		kc26 {
			if {[llength ${args}]} {
				set descr [lindex ${args} 0]
			} else {
				set descr ${var}
			}
			puts ${fh} "config ${var}"
			puts ${fh} "\tstring \"${descr}\""
			puts ${fh} "\tdefault \"${val}\""
			put_blank_line ${fh}
		}
		default {}
	}
}

proc put_cfg_ena {fh var} {
	debug jabber "${var} <-- define/yes"
	switch [get_file_type ${fh}] {
		ch { puts ${fh} [format "#define %-40s" ${var}] }
		mk { puts ${fh} [format "%-8s = y" ${var}] }
		default {}
	}
}

proc put_cfg_dis {fh var} {
	debug jabber "${var} <-- undef/no"
	switch [get_file_type ${fh}] {
		ch { puts ${fh} [format "#undef  %-40s" ${var}] }
		mk { puts ${fh} [format "%-8s = n" ${var}] }
		default {}
	}
}

proc put_var_append {fh var val} {
	debug jabber "${var} += ${val}"
	switch [get_file_type ${fh}] {
		mk { puts ${fh} [format "%-8s += %s" ${var} ${val}] }
		default {}
	}
}

proc put_ch_header {fh desc vers} {
	puts ${fh} "/*"
	puts ${fh} " * (C) Copyright 2007-2009 Michal Simek"
	puts ${fh} " * Michal SIMEK <monstr@monstr.eu>"
	puts ${fh} " *"
	puts ${fh} " * (C) Copyright 2010 Li-Pro.Net"
	puts ${fh} " * Stephan Linz <linz@li-pro.net>"
	puts ${fh} " *"
	puts ${fh} " * This program is free software; you can redistribute it and/or"
	puts ${fh} " * modify it under the terms of the GNU General Public License as"
	puts ${fh} " * published by the Free Software Foundation; either version 2 of"
	puts ${fh} " * the License, or (at your option) any later version."
	puts ${fh} " *"
	puts ${fh} " * This program is distributed in the hope that it will be useful,"
	puts ${fh} " * but WITHOUT ANY WARRANTY; without even the implied warranty of"
	puts ${fh} " * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the"
	puts ${fh} " * GNU General Public License for more details."
	puts ${fh} " *"
	puts ${fh} " * You should have received a copy of the GNU General Public License"
	puts ${fh} " * along with this program; if not, write to the Free Software"
	puts ${fh} " * Foundation, Inc., 59 Temple Place, Suite 330, Boston,"
	puts ${fh} " * MA 02111-1307 USA"
	puts ${fh} " *"
	puts ${fh} " * CAUTION: This file is automatically generated by libgen."
	puts ${fh} " * Version: [xget_swverandbld]"
	puts ${fh} " * Description: ${desc}"
	puts ${fh} " *"
	puts ${fh} " * Generate by ${vers}"
	puts ${fh} " * Project description at http://www.monstr.eu/"
	puts ${fh} " */"
	puts ${fh} ""
}

proc put_mk_header {fh desc vers} {
	puts ${fh} "\#"
	puts ${fh} "\# (C) Copyright 2007-2009 Michal Simek"
	puts ${fh} "\# Michal SIMEK <monstr@monstr.eu>"
	puts ${fh} "\#"
	puts ${fh} "\# (C) Copyright 2010 Li-Pro.Net"
	puts ${fh} "\# Stephan Linz <linz@li-pro.net>"
	puts ${fh} "\#"
	puts ${fh} "\# This program is free software; you can redistribute it and/or"
	puts ${fh} "\# modify it under the terms of the GNU General Public License as"
	puts ${fh} "\# published by the Free Software Foundation; either version 2 of"
	puts ${fh} "\# the License, or (at your option) any later version."
	puts ${fh} "\#"
	puts ${fh} "\# This program is distributed in the hope that it will be useful,"
	puts ${fh} "\# but WITHOUT ANY WARRANTY; without even the implied warranty of"
	puts ${fh} "\# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the"
	puts ${fh} "\# GNU General Public License for more details."
	puts ${fh} "\#"
	puts ${fh} "\# You should have received a copy of the GNU General Public License"
	puts ${fh} "\# along with this program; if not, write to the Free Software"
	puts ${fh} "\# Foundation, Inc., 59 Temple Place, Suite 330, Boston,"
	puts ${fh} "\# MA 02111-1307 USA"
	puts ${fh} "\#"
	puts ${fh} "\# CAUTION: This file is automatically generated by libgen."
	puts ${fh} "\# Version: [xget_swverandbld]"
	puts ${fh} "\# Description: ${desc}"
	puts ${fh} "\#"
	puts ${fh} "\# Generate by ${vers}"
	puts ${fh} "\# Project description at http://www.monstr.eu/"
	puts ${fh} "\#"
	puts ${fh} ""
}

proc put_kc24_header {fh desc vers} {
	put_mk_header ${fh} ${desc} ${vers}
}

proc put_kc26_header {fh desc vers} {
	put_mk_header ${fh} ${desc} ${vers}
}

