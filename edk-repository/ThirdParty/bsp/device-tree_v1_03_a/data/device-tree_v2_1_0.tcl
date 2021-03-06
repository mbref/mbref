#
# EDK BSP board generation for device trees supporting Microblaze and PPC
#
# (C) Copyright 2007-2012 Xilinx, Inc.
#
# Based on original code:
# (C) Copyright 2007-2011 PetaLogix Qld Pty Ltd
#
# (C) Copyright 2007-2010 Michal Simek
# Michal SIMEK <monstr@monstr.eu>
#
# (C) Copyright 2010-2012 Li-Pro.Net
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
# Project description at http://www.monstr.eu/fdt/
#

#############################################################################
#   Exported variables
#
variable pkg_name
variable pkg_version
variable devtree_verstr
variable cpunumber
variable periphery_array
variable serial_count
variable uartlite_count
variable uart16550_count
variable ethernet_count
variable mac_count
variable phy_count
variable rtc_count
variable sf_count

#############################################################################
#  Package meta
#
set pkg_name	"device-tree"
set pkg_version	"1.03.a"

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

#############################################################################
#   Global variables
#
set devtree_verstr [get_version_string ${pkg_name} ${pkg_version}]

# cpu parameters to generate the DTS (achieve in parts from the MLD file):
set cpunumber 0
set periphery_array ""
set axi_ifs ""
set serial_count 0
set uartlite_count 0
set uart16550_count 0
set mac_count 0
set ethernet_count 0
set phy_count 0
set rtc_count 0
set sf_count 0
set gpio_names {}
set overrides {}

# misc
set alias_node_list {}
set generic_uio_list {}

#############################################################################
#   DRC			the name of the DRC given in the MLD file
#			(DRC => Design Rule Check)
#
proc device_tree_drc {os_handle} {
	variable devtree_verstr
	debug info "\#--------------------------------------"
	debug info "\# ${devtree_verstr} BSP DRC...!"
	debug info "\#--------------------------------------"
}

#############################################################################
#   generate		Libgen defined procedure called after OS and library
#			files are copied
#
proc generate {os_handle} {
	variable devtree_verstr

	debug info "\#--------------------------------------"
	debug info "\# ${devtree_verstr} BSP generate..."
	debug info "\#--------------------------------------"

	set bootargs [xget_sw_parameter_value $os_handle "linux_bootargs"]
	set consoleip [xget_sw_parameter_value $os_handle "stdout"]
	variable overrides
	set overrides [xget_sw_parameter_value $os_handle "periph_type_overrides"]
	global main_memory
	set main_memory [xget_sw_parameter_value $os_handle "main_memory"]
	global main_memory_bank
	set main_memory_bank [xget_sw_parameter_value $os_handle "main_memory_bank"]
	global main_memory_size
	set main_memory_size [xget_sw_parameter_value $os_handle "main_memory_size"]
	global flash_memory
	set flash_memory [xget_sw_parameter_value $os_handle "flash_memory"]
	global flash_memory_bank
	set flash_memory_bank [xget_sw_parameter_value $os_handle "flash_memory_bank"]
	global timer
	set timer [xget_sw_parameter_value $os_handle "timer"]

	# FIXME: Why we have to set generic_uio_list here?
	#        Why is global setup invalid? (see above around line 110-115)
	# This hot fix avoid effects of missing variable in ISE 11.5 and 12.1:
	#   ERROR:EDK - tpos () - can't read "generic_uio_list": no such variable 
	#   ERROR:EDK:1188 - Error(s) while running "generate" for processor microblaze_0.
	global generic_uio_list
	set generic_uio_list {}
	set generic_uio_handle [xget_handle $os_handle "ARRAY" "generic_uio_list"]
        if {![string match "" ${generic_uio_handle}] && ![string match -nocase "none" ${generic_uio_handle}]} {
		set generic_uio_elements [xget_handle $generic_uio_handle "ELEMENTS" "*"]
		foreach ele $generic_uio_elements {
			set generic_uio  [xget_value $ele "PARAMETER" "generic_uio"]
			lappend generic_uio_list $generic_uio
		}
	}

	generate_device_tree "xilinx.dts" $bootargs $consoleip
}

#############################################################################
#   post_generate	Libgen defined procedure called after generate has
#			been called on all OSs, drivers, and libraries
#
proc post_generate {lib_handle} {
	# nothing to do (perhaps not yet)
}

#############################################################################
#   Local functions
#
proc generate_device_tree {filepath bootargs {consoleip ""}} {
	variable pkg_version
	debug info "--- device tree generator version: v${pkg_version} ---"
	debug info "generating $filepath"

	set toplevel {}
	set ip_tree {}

	set proc_handle [xget_libgen_proc_handle]
	set hwproc_handle [xget_handle $proc_handle "IPINST"]

	# Clock port summary
	debug clock "Clock Port Summary:"
	set mhs_handle [xget_hw_parent_handle $hwproc_handle]
	set ips [xget_hw_ipinst_handle $mhs_handle "*"]
	foreach ip $ips {
		set ipname [xget_hw_name $ip]
		set ports [xget_hw_port_handle $ip "*"]
		foreach port $ports {
			set sigis [xget_hw_subproperty_value $port "SIGIS"]
			if {[string toupper $sigis] == "CLK"} {
				set portname [xget_hw_name $port]
				# EDK doesn't compute clocks for ports that aren't connected.
				set connected_port [xget_hw_port_value $ip $portname]
				if {[llength $connected_port] != 0} {
					set frequency [get_clock_frequency $ip $portname]
					if {$frequency == ""} {
						set connected_bus [get_clock_frequency $ip $portname]
						set frequency "WARNING: no frequency found!"
					}
					debug clock "$ipname.$portname connected to $connected_port:"
					debug clock "    CLK_FREQ_HZ = $frequency"
					set dir [xget_hw_subproperty_value $port "DIR"]
					set inport [xget_hw_subproperty_value $port "CLK_INPORT"]
					set factor [xget_hw_subproperty_value $port "CLK_FACTOR"]
					if {[string toupper $dir] == "O"} {
						debug clock "    CLK_INPORT = $inport"
						debug clock "    CLK_FACTOR = $factor"
					}
				}
			}
		}
	}

	set proctype [xget_value $hwproc_handle "OPTION" "IPNAME"]
	switch $proctype {
		"microblaze" {
			# Microblaze linux system requires dual-channel timer
			global timer
			if { [string match "" $timer] || [string match "none" $timer] } {
				debug warning "ERROR: No timer is specified in the system. Linux requires dual channel timer."
				exit 1
			}

			set intc [get_handle_to_intc $proc_handle "Interrupt"]
			set toplevel [gen_microblaze $toplevel $hwproc_handle [default_parameters $hwproc_handle]]

			# If is AXI system then it is necessary to load all slave IPs connected
			# to DC because there is FLASH which isn't handled by DP.
			# AXI DC slave IPs are added in bus_bridge function.
			set bus_name [xget_hw_busif_value $hwproc_handle "M_AXI_DC"]
			if { [string compare -nocase $bus_name ""] != 0 } {
				global axi_ifs
				set axi_ifs [xget_hw_connected_busifs_handle $mhs_handle $bus_name "slave"]
			}
			# Microblaze v8 has AXI and/or PLB. xget_hw_busif_handle returns
			# a valid handle for both these bus ifs, even if they are not
			# connected. The better way of checking if a bus is connected
			# or not is to check it's value.
			set bus_name [xget_hw_busif_value $hwproc_handle "M_AXI_DP"]
			if { [string compare -nocase $bus_name ""] != 0 } {
				set tree [bus_bridge $hwproc_handle $intc 0 "M_AXI_DP"]
				set tree [tree_append $tree [list ranges empty empty]]
				lappend ip_tree $tree
			}
			set bus_name [xget_hw_busif_value $hwproc_handle "DPLB"]
			if { [string compare -nocase $bus_name ""] != 0 } {
				# Microblaze v7 has PLB.
				set tree [bus_bridge $hwproc_handle $intc 0 "DPLB"]
				set tree [tree_append $tree [list ranges empty empty]]
				lappend ip_tree $tree
			}
			set bus_name [xget_hw_busif_value $hwproc_handle "DOPB"]
			if { [string compare -nocase $bus_name ""] != 0 } {
				# Older microblazes have OPB.
				set tree [bus_bridge $hwproc_handle $intc 0 "DOPB"]
				set tree [tree_append $tree [list ranges empty empty]]
				lappend ip_tree $tree
			}
			lappend toplevel [list "compatible" stringtuple [list "xlnx,microblaze"] ]
		}
		"ppc405" -
		"ppc405_virtex4" {
			set intc [get_handle_to_intc $proc_handle "EICC405EXTINPUTIRQ"]
			set toplevel [gen_ppc405 $toplevel $hwproc_handle [default_parameters $hwproc_handle]]
			set busif_handle [xget_hw_busif_handle $hwproc_handle "DPLB"]
			if {[llength $busif_handle] != 0} {
				# older ppc405s have a single PLB interface.
				set tree [bus_bridge $hwproc_handle $intc 0 "DPLB"]
				set tree [tree_append $tree [list ranges empty empty]]
				lappend ip_tree $tree
			} else {
				# newer ppc405s since edk9.2 have two plb interfaces, with
				# DPLB1 only being used for memory.
				set tree [bus_bridge $hwproc_handle $intc 0 "DPLB0"]
				set tree [tree_append $tree [list ranges empty empty]]
				lappend ip_tree $tree
				set tree [bus_bridge $hwproc_handle $intc 1 "DPLB1"]
				set tree [tree_append $tree [list ranges empty empty]]
				lappend ip_tree $tree
			}
			# pickup things which are only on the dcr bus.
			if {[bus_is_connected $hwproc_handle "MDCR"]} {
				set tree [bus_bridge $hwproc_handle $intc 0 "MDCR"]
				lappend ip_tree $tree
			}

			lappend toplevel [list "compatible" stringtuple [list "xlnx,virtex405" "xlnx,virtex"] ]
		}
		"ppc440_virtex5" {
			set intc [get_handle_to_intc $proc_handle "EICC440EXTIRQ"]
			set toplevel [gen_ppc440 $toplevel $hwproc_handle $intc [default_parameters $hwproc_handle]]
			set tree [bus_bridge $hwproc_handle $intc 0 "MPLB"]
			set tree [tree_append $tree [list ranges empty empty]]
			lappend ip_tree $tree
			# pickup things which are only on the dcr bus.
			if {[bus_is_connected $hwproc_handle "MDCR"]} {
				set tree [bus_bridge $hwproc_handle $intc 0 "MDCR"]
				lappend ip_tree $tree
			}

# 			set tree [bus_bridge $hwproc_handle $intc 0 "PPC440MC"]
# 			set tree [tree_append $tree [list ranges empty empty]]
# 			lappend ip_tree $tree

			lappend toplevel [list "compatible" stringtuple [list "xlnx,virtex440" "xlnx,virtex"] ]
			set cpu_name [xget_hw_name $hwproc_handle]
			lappend toplevel [list "dcr-parent" labelref $cpu_name]
		}
		default {
			error "unsupported CPU"
		}
	}

	variable serial_count
	variable alias_node_list
	puts "$serial_count $alias_node_list"

	if {[llength $bootargs] == 0} {
		# default number for ttyULX or ttySX is 0
		set serial_number ""
		# find out which serial number is my choose uart - from aliases node - there is correct order
		foreach node $alias_node_list {
			if { "[lindex $node 2]" == "$consoleip" } {
				set serial_number "[lindex $node 3]"
			}
		}

		# check serial_number value - if is not setup it means that console is not supported
		# For example if MDM interrupt is not setup
		if {[llength $serial_number] == 0} {
			error "unsupported console - Please check that all required pins are connected."
		}

		# generate default string for uart16550 or uartlite
		set uart_handle [xget_sw_ipinst_handle_from_processor [xget_libgen_proc_handle] $consoleip]
		switch -exact [xget_value $uart_handle "VALUE"] {
			"axi_uart16550" -
			"xps_uart16550" -
			"plb_uart16550" -
			"opb_uart16550" {
				# for uart16550 is default string 115200
				set bootargs "console=ttyS$serial_number,115200"
			}
			"axi_uartlite" -
			"xps_uartlite" -
			"opb_uartlite" {
				set bootargs "console=ttyUL$serial_number,[xget_sw_parameter_value $uart_handle "C_BAUDRATE"]"
			}
			"mdm" {
				set bootargs "console=ttyUL$serial_number,115200"
			}
			default {
				debug warning "WARNING: Unsupported console ip $consoleip. Can't generate bootargs."
			}
		}
	}

	set chosen {}
	lappend chosen [list bootargs string $bootargs]

	set dev_tree [concat $toplevel $ip_tree]
	if {$consoleip != ""} {
		set consolepath [get_pathname_for_label $dev_tree $consoleip]
		if {$consolepath != ""} {
			lappend chosen [list "linux,stdout-path" string $consolepath]
		} else {
			debug warning "WARNING: console ip $consoleip was not found.  This may prevent output from appearing on the boot console."
		}
	} else {
		debug warning "WARNING: no console ip was specified.  This may prevent output from appearing on the boot console."
	}

	lappend toplevel [list \#size-cells int 1]
	lappend toplevel [list \#address-cells int 1]
	lappend toplevel [list model string [file tail [get_project_folder]]]

	set reset [reset_gpio]
	if { "$reset" != "" } {
		lappend toplevel $reset
	}
	lappend toplevel [list chosen tree $chosen]

	#
	# Add the alias section to toplevel
	#
	lappend toplevel [list aliases tree $alias_node_list]
	
	set toplevel [gen_memories $toplevel $hwproc_handle]

	set toplevel_file [open $filepath w]
	headerc $toplevel_file ${pkg_version}
	puts $toplevel_file "/dts-v1/;"
	puts $toplevel_file "/ {"
	write_tree 0 $toplevel_file $toplevel
	write_tree 0 $toplevel_file $ip_tree
	puts $toplevel_file "} ;"
	close $toplevel_file
}

proc headerc {ufile generator_version} {
	puts $ufile "/*"
	puts $ufile " * Device Tree Generator version: $generator_version"
	puts $ufile " *"
	puts $ufile " * (C) Copyright 2007-2012 Xilinx, Inc."
	puts $ufile " *"
	puts $ufile " * Based on original code:"
	puts $ufile " * (C) Copyright 2007-2011 PetaLogix Qld Pty Ltd"
	puts $ufile " *"
	puts $ufile " * (C) Copyright 2007-2010 Michal Simek"
	puts $ufile " * Michal SIMEK <monstr@monstr.eu>"
	puts $ufile " *"
	puts $ufile " * (C) Copyright 2010-2012 Li-Pro.Net"
	puts $ufile " * Stephan Linz <linz@li-pro.net>"
	puts $ufile " *"
	puts $ufile " * This program is free software; you can redistribute it and/or"
	puts $ufile " * modify it under the terms of the GNU General Public License as"
	puts $ufile " * published by the Free Software Foundation; either version 2 of"
	puts $ufile " * the License, or (at your option) any later version."
	puts $ufile " *"
	puts $ufile " * This program is distributed in the hope that it will be useful,"
	puts $ufile " * but WITHOUT ANY WARRANTY; without even the implied warranty of"
	puts $ufile " * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the"
	puts $ufile " * GNU General Public License for more details."
	puts $ufile " *"
	puts $ufile " * You should have received a copy of the GNU General Public License"
	puts $ufile " * along with this program; if not, write to the Free Software"
	puts $ufile " * Foundation, Inc., 59 Temple Place, Suite 330, Boston,"
	puts $ufile " * MA 02111-1307 USA"
	puts $ufile " *"
	puts $ufile " * CAUTION:  This file is automatically generated by libgen."
	puts $ufile " * Version:  [xget_swverandbld]"
	puts $ufile " * [clock format [clock seconds] -format {Today is: %A, the %d of %B, %Y; %H:%M:%S}]"
	puts $ufile " *"
	puts $ufile " * XPS project directory: [file tail [get_project_folder]]"
	puts $ufile " */"
	puts $ufile ""
}

# generate structure for PHY chip on mdio.
# {key-word IP_name chip_compat chip_addr chip_irq_connector}
# chip_irq_connector can lack for chips without interrupt line
#
# PARAMETER periph_type_overrides = {phy-mdio Ethernet_MAC marvell,88e1111 7}
proc phy_mdio {slave intc} {
	variable overrides
	variable phy_count
	set tree {}
	foreach over $overrides {
		# parse phy-mdio keyword
		if {[lindex $over 0] == "phy-mdio"} {
			# search if that ethernet name is valid IP core in system
			set desc [valid_ether [xget_hw_name $slave] [lindex $over 1]]
			if { "$desc" != "" } {
				set compat [lindex $over 2]
				set addr [valid_mdio_addr [lindex $over 3]]
				# check if is a compat string and valid mdio address
				if { "$compat" != "" &&  "$addr" != "" } {
					#set devicetype [xget_hw_value $slave]
					#set name [format_ip_name $devicetype $addr "phy$phy_count"]
					set name [format_ip_name phy $addr "phy$phy_count"]
					set tree [list $name tree {}]
					set tree [tree_append $tree [list "reg" int $addr]]
					set tree [tree_append $tree [list "device_type" string "ethernet-phy"]]
					set tree [tree_append $tree [list "compatible" string $compat]]
					set connect [lindex $over 4]
					# check if is a interrup connection
					if { "$connect" != "" } {
						set proc_handle [xget_libgen_proc_handle]
						set hwproc_handle [xget_handle $proc_handle "IPINST"]
						set mhs_handle [xget_hw_parent_handle $hwproc_handle]
						set tree [gen_interrupt_property_mhs $tree $mhs_handle $intc [list $connect]]
					}
					incr phy_count
				} else {
					debug warning "WARNING: PHY-MDIO: Missing compat-name or wrong address. Can't generate correct."
				}
# NOT APPLICABLE	} else {
# NOT APPLICABLE		puts "PHY-MDIO: Not valid IP name $over"
			}
		}
	}
	return $tree
}

# Check if ethernet name is valid or not
proc valid_ether {slave_name over_name} {
	if { "$slave_name" == "$over_name" } {
		return $slave_name
	}
	return
}

# Check if mdio addr is valid or not
proc valid_mdio_addr {addr} {
	if { ![string match "" $addr] && [expr {$addr & 0x1f}] } {
		return $addr
	}
	return
}

# generate structure for RTC chip on iic.
# {key-word IP_name chip_compat chip_addr chip_irq_connector}
# chip_irq_connector can lack for chips without interrupt line
#
# PARAMETER periph_type_overrides = {rtc-iic IIC_Bus dallas,ds3232 0x68}
proc rtc_iic {slave intc} {
	variable overrides
	variable rtc_count
	set tree {}
	foreach over $overrides {
		# parse rtc-iic keyword
		if {[lindex $over 0] == "rtc-iic"} {
			# search if that iic name is valid IP core in system
			set desc [valid_iic [xget_hw_name $slave] [lindex $over 1]]
			if { "$desc" != "" } {
				set compat [lindex $over 2]
				set addr [valid_iic_addr [lindex $over 3]]
				# check if is a compat string and valid iic address
				if { "$compat" != "" &&  "$addr" != "" } {
					set devicetype [xget_hw_value $slave]
					set name [format_ip_name $devicetype $addr "rtc$rtc_count"]
					set tree [list $name tree {}]
					set tree [tree_append $tree [list "reg" hexinttuple $addr]]
					set tree [tree_append $tree [list "device_type" string "rtc"]]
					set tree [tree_append $tree [list "compatible" string $compat]]
					set connect [lindex $over 4]
					# check if is a interrup connection
					if { "$connect" != "" } {
						set proc_handle [xget_libgen_proc_handle]
						set hwproc_handle [xget_handle $proc_handle "IPINST"]
						set mhs_handle [xget_hw_parent_handle $hwproc_handle]
						set tree [gen_interrupt_property_mhs $tree $mhs_handle $intc [list $connect]]
					}
					incr rtc_count
				} else {
					debug warning "WARNING: RTC-IIC: Missing compat-name or wrong address. Can't generate correct."
				}
# NOT APPLICABLE	} else {
# NOT APPLICABLE		puts "RTC-IIC: Not valid IP name $over"
			}
		}
	}
	return $tree
}

# Check if iic name is valid or not
proc valid_iic {slave_name over_name} {
	if { "$slave_name" == "$over_name" } {
		return $slave_name
	}
	return
}

# Check if iic addr is valid or not
proc valid_iic_addr {addr} {
	if { ![string match "" $addr] && [expr {$addr & 0x7f}]
	&& $addr != 1 && $addr != 2 && $addr != 3 && $addr != 4
	&& $addr != 5 && $addr != 6 && $addr != 7 && $addr != 0x78
	&& $addr != 0x79 && $addr != 0x7a && $addr != 0x7b && $addr != 0x7c
	&& $addr != 0x7d && $addr != 0x7e && $addr != 0x7f } {
		return $addr
	}
	return
}

# generate structure for Flash chip on spi.
# {key-word IP_name chip_compat chip_ss}
#
# PARAMETER periph_type_overrides = {flash-spi SPI_FLASH micron,n25q128 0}
proc flash_spi {slave intc} {
	variable overrides
	variable sf_count
	global flash_memory
	global flash_memory_bank
	set tree {}
	foreach over $overrides {
		# parse flash-spi keyword
		if {[lindex $over 0] == "flash-spi"} {
			# search if that spi name is valid IP core in system
			set desc [valid_spi [xget_hw_name $slave] [lindex $over 1]]
			if { "$desc" != "" } {
				set compat [lindex $over 2]
				set ssmax [scan_int_parameter_value $slave "C_NUM_SS_BITS"]
				set ss [valid_spi_ss $ssmax [lindex $over 3]]
				if { [string match -nocase $flash_memory $desc] && $flash_memory_bank ==  $ss } {
					set entry_name "primary_flash"
				} else {
					set entry_name "spi_flash$sf_count"
				}
				# check if is a compat string and valid iic address
				if { "$compat" != "" &&  "$ss" != "" } {
					set devicetype [xget_hw_value $slave]
					set name [format_ip_name $devicetype $ss $entry_name]
					set tree [list $name tree {}]
					set tree [tree_append $tree [list "reg" hexinttuple $ss]]
					set tree [tree_append $tree [list "compatible" string $compat]]
					# Set the SPI Flash clock freqeuncy
					if { $devicetype == "axi_spi" } {
						set sys_clk [get_clock_frequency $slave "S_AXI_ACLK"]
					} else {
						set sys_clk [get_clock_frequency $slave "SPLB_Clk"]
					}
					set sck_ratio [scan_int_parameter_value $slave "C_SCK_RATIO"]
					set sck [expr { $sys_clk / $sck_ratio }]
					set tree [tree_append $tree [list "spi-max-frequency" int $sck]]
					incr sf_count
				} else {
					debug warning "WARNING: FLASH-SPI: Missing compat-name or slave select. Can't generate correct."
				}
# NOT APPLICABLE	} else {
# NOT APPLICABLE		puts "FLASH-SPI: Not valid IP name $over"
			}
		}
	}
	return $tree
}

# Check if spi name is valid or not
proc valid_spi {slave_name over_name} {
	if { "$slave_name" == "$over_name" } {
		return $slave_name
	}
	return
}

# Check if spi slave select is valid or not
proc valid_spi_ss {maxss ss} {
	if { ![string match "" $ss] && $ss < $maxss } {
		return $ss
	}
	return
}

# generate structure for reset gpio.
# mss description - first pin of Reset_GPIO ip is used for system reset
# {key-word IP_name gpio_pin size_of_pin}
# for reset-gpio is used only size equals 1
#
# PARAMETER periph_type_overrides = {hard-reset-gpios Reset_GPIO 1 1}
proc reset_gpio {} {
	variable overrides
	# ignore size parameter
	set reset {}
	foreach over $overrides {
		# parse hard-reset-gpio keyword
		if {[lindex $over 0] == "hard-reset-gpios"} {
			# search if that gpio name is valid IP core in system
			set desc [valid_gpio [lindex $over 1]]
			if { "$desc" != "" } {
				# check if is pin larger then gpio width
				if {[lindex $desc 1] > [lindex $over 2]} {
					set k [ list [lindex $over 1] [lindex $over 2] 1]
					set reset "hard-reset-gpios labelref-ext {{$k}}"
					return $reset
				} else {
					puts "RESET-GPIO: Requested pin is greater than number of GPIO pins: $over"
				}
			} else {
				puts "RESET-GPIO: Not valid IP name: $over"
			}
		}
	}
	return
}

# For generation of gpio led description
# this function is called from bus code because linux needs to have this description in the same node as is IP
# FIXME there could be maybe problem if system contains bridge and gpio is after it - needs test
#
# PARAMETER periph_type_overrides = {led heartbeat LEDs_8Bit 5 5} {led yellow LEDs_8Bit 7 2} {led green LEDs_8Bit 4 1}
proc led_gpio {} {
	variable overrides
	set tree {}
	foreach over $overrides {
		# parse hard-reset-gpio keyword
		if {[lindex $over 0] == "led"} {
			# clear trigger
			set trigger ""
			set desc [valid_gpio [lindex $over 2]]
			if { "$desc" != "" } {
				# check if is pin larger then gpio width
				if { [lindex $desc 1] > [lindex $over 3]} {
					# check if the size exceed number of pins
					if { [lindex $desc 1] >= [expr [lindex $over 3] + [lindex $over 4]] } {
						# assemble led node
						set label_desc "{label string [lindex $over 1]}"
						set led_pins "{[lindex $over 2] [lindex $over 3] [lindex $over 4]}"
						if { [string match -nocase "heartbeat" [lindex $over 1]] } {
							set trigger "{linux,default-trigger string heartbeat}"
						}
						set tree "{[lindex $over 1] tree { $label_desc $trigger { gpios labelref-ext $led_pins }}} $tree"
					} else {
						puts "LED-GPIO: Requested pin size reach out of GPIO pins width: $over"
					}

				} else {
					puts "LED-GPIO: Requested pin is greater than number of GPIO pins: $over"
				}
			} else {
				puts "LED-GPIO: Not valid IP name $over"
			}
		}
	}
	# it is a complex node that's why I have to assemble it
	if { "$tree" != "" } {
		set tree "gpio-leds tree { {compatible string gpio-leds} $tree }"
	}
	return $tree
}

# Check if gpio name is valid or not
proc valid_gpio {name} {
	global gpio_names
	foreach gpio_desc $gpio_names {
		if { [lindex $gpio_desc 0] == "$name" } {
			return $gpio_desc
		}
	}
	return
}

proc get_intc_signals {intc} {
	set signals [split [xget_hw_port_value $intc "intr"] "&"]
	set intc_signals {}
	foreach signal $signals {
		lappend intc_signals [string trim $signal]
	}
	return $intc_signals
}

# Get interrupt number
proc get_intr_algo {intc intc_value port_handle} {
	if {![string match "" $intc] && ![string match -nocase "none" $intc]} {
		set intc_signals [get_intc_signals $intc]
		set interrupt_signal [xget_value $port_handle "VALUE"]
		set index [lsearch $intc_signals $interrupt_signal]
		if {$index == -1} {
			return -1
		} else {
			# interrupt 0 is last in list.
			return [expr [llength $intc_signals] - $index - 1]
		}
	} else {
		return -1
	}
}

proc get_intr {ip_handle intc intc_value port_name} {
	set port_handle [xget_hw_port_handle $ip_handle "$port_name"]
	if {![string match "" $port_handle] && ![string match -nocase "none" $port_handle]} {
		return [get_intr_algo $intc $intc_value $port_handle]
	} else {
		debug warning "WARNING: Unknown port name was found. Can't generate correct."
		return -1
	}
}

proc get_intr_mhs {mhs intc intc_value connector_name} {
	set port_handle [xget_hw_connected_ports_handle $mhs "$connector_name" "source"]
	if {![string match "" $port_handle] && ![string match -nocase "none" $port_handle]} {
		return [get_intr_algo $intc $intc_value $port_handle]
	} else {
		debug warning "WARNING: Unknown connector name was found. Can't generate correct."
		return -1
	}
}

proc get_intr_type_algo {ip_name port_handle error_string} {
	set sensitivity [xget_hw_subproperty_value $port_handle "SENSITIVITY"];
	# Follow the openpic specification
	if { [string compare -nocase $sensitivity "EDGE_FALLING"] == 0 } {
		return 3;
	} elseif { [string compare -nocase $sensitivity "EDGE_RISING"] == 0 } {
		return 0;
	} elseif { [string compare -nocase $sensitivity "LEVEL_HIGH"] == 0 } {
		return 2;
	} elseif { [string compare -nocase $sensitivity "LEVEL_LOW"] == 0 } {
		return 1;
	} else {
		error "Unknown interrupt sensitivity on $error_string of $ip_name was $sensitivity"
	}
}

proc get_intr_type {ip_handle port_name} {
	set ip_name [xget_hw_name $ip_handle]
	set port_handle [xget_hw_port_handle $ip_handle "$port_name"]
	if {![string match "" $port_handle] && ![string match -nocase "none" $port_handle]} {
		return [get_intr_type_algo $ip_name $port_handle "port $port_name"]
	} else {
		error "Unknown interrupt line on port $port_name of $ip_name"
	}
}

proc get_intr_type_mhs {mhs connector_name} {
	set port_handle [xget_hw_connected_ports_handle $mhs "$connector_name" "source"]
	if {![string match "" $port_handle] && ![string match -nocase "none" $port_handle]} {
		return [get_intr_type_algo "MHS" $port_handle "connector $connector_name"]
	} else {
		error "Unknown interrupt line on connector $connector_name of MHS"
	}
}

# Generate a template for a compound slave, such as the ll_temac or
# the opb_ps2_dual_ref
proc compound_slave {slave {baseaddrname "C_BASEADDR"}} {
	set baseaddr [scan_int_parameter_value $slave ${baseaddrname}]
	set ip_name [xget_hw_name $slave]
	set ip_type [xget_hw_value $slave]
	set tree [list [format_ip_name $ip_type $baseaddr $ip_name] tree {}]
	set tree [tree_append $tree [list \#size-cells int 1]]
	set tree [tree_append $tree [list \#address-cells int 1]]
	set tree [tree_append $tree [list compatible stringtuple [list "xlnx,compound"]]]
	return $tree
}

proc slaveip_intr {slave intc interrupt_port_list devicetype params {baseaddr_prefix ""} {dcr_baseaddr_prefix ""} {other_compatibles {}} } {
	set tree [slaveip $slave $intc $devicetype $params $baseaddr_prefix $other_compatibles]
	return [gen_interrupt_property $tree $slave $intc $interrupt_port_list]
}

proc get_dcr_parent_name {slave face} {
	set busif_handle [xget_hw_busif_handle $slave $face]
	if {[llength $busif_handle] == 0} {
		error "Bus handle $face not found!"
	}
	set bus_name [xget_hw_value $busif_handle]

	debug ip "IP on DCR bus $bus_name"
	debug handles "  bus_handle: $busif_handle"
	set mhs_handle [xget_hw_parent_handle $slave]
	set bus_handle [xget_hw_ipinst_handle $mhs_handle $bus_name]

	set master_ifs [xget_hw_connected_busifs_handle $mhs_handle $bus_name "master"]
	if {[llength $master_ifs] == 1} {
		set ip_handle [xget_hw_parent_handle [lindex $master_ifs 0 0]]
		set ip_name [xget_hw_name $ip_handle]
		return $ip_name
	} else {
		error "DCR bus found which does not have exactly one master.  Masters were $master_ifs"
	}
}

proc append_dcr_interface {tree slave {dcr_baseaddr_prefix ""} } {
	set name [xget_hw_name $slave]
	set baseaddr [scan_int_parameter_value $slave [format "C_DCR%s_BASEADDR" $dcr_baseaddr_prefix]]
	set highaddr [scan_int_parameter_value $slave [format "C_DCR%s_HIGHADDR" $dcr_baseaddr_prefix]]
	set tree [tree_append $tree [gen_reg_property $name $baseaddr $highaddr "dcr-reg"]]
	set name [get_dcr_parent_name $slave "SDCR"]
	set tree [tree_append $tree [list "dcr-parent" labelref $name]]
	return $tree
}

# Many IP's (e.g. xps_tft) can be connected to dcr or plb control busses.
proc slaveip_dcr_or_plb {slave intc devicetype params {baseaddr_prefix ""} {other_compatibles {}} } {
	# Get the value of the parameter which indicates about the interface
	# on which the core is connected.
	set bus_name  [scan_int_parameter_value $slave "C_DCR_SPLB_SLAVE_IF"]

	# '1' indicates core connected on PLB bus directly
	# '0' indicates core connected on DCR bus directly
	if {$bus_name == "1"} {
		if {[parameter_exists $slave "C_PLB_BASEADDR"] != 0} {
			return [slaveip $slave $intc $devicetype $params "PLB_" $other_compatibles]
		} else {
			return [slaveip $slave $intc $devicetype $params "SPLB_" $other_compatibles]
		}
	} else {
		# When the core is connected directly on the DCR bus
		return [slaveip_dcr $slave $intc "tft" [default_parameters $slave] "DCR_" $other_compatibles]
	}
}

# DCR addresses are usually word addresses, not byte addresses.  The
# device tree always handles byte address.
proc slaveip_dcr {slave intc devicetype params {baseaddr_prefix ""} {other_compatibles {}} } {
	set dcr_baseaddr [scan_int_parameter_value $slave [format "C_%sBASEADDR" $baseaddr_prefix]]
	set name [xget_hw_name $slave]
	set type [xget_hw_value $slave]
	if {$devicetype == ""} {
		set devicetype $type
	}
	set tree [slaveip_basic $slave $intc $params [format_ip_name $devicetype $dcr_baseaddr $name] $other_compatibles]
	set dcr_busif_handle [xget_hw_busif_handle $slave "SDCR"]
	if {[llength $dcr_busif_handle] != 0} {
		# Hmm.. looks like there's a dcr interface.
		set tree [append_dcr_interface $tree $slave]
	}

	# Backward compatibility to not break older style tft driver
	# connected through opb2dcr bridge.
	set dcr_highaddr [scan_int_parameter_value $slave [format "C_%sHIGHADDR" $baseaddr_prefix]]
	# DCR addresses are word-based addresses.  Here we convert to the
	# correct byte ranges that subsume the word ranges.  This is tricky
	# in the case of the high address, since we multiply the length by
	# 4 and then have to convert back to the correct address.
	set scaled_baseaddr [expr $dcr_baseaddr * 4]
	set scaled_highaddr [expr ($dcr_highaddr + 1) * 4 - 1]
	set tree [tree_append $tree [gen_reg_property $name $scaled_baseaddr $scaled_highaddr]]

	return $tree
}

proc slaveip {slave intc devicetype params {baseaddr_prefix ""} {other_compatibles {}} } {
	set baseaddr [scan_int_parameter_value $slave [format "C_%sBASEADDR" $baseaddr_prefix]]
	set highaddr [scan_int_parameter_value $slave [format "C_%sHIGHADDR" $baseaddr_prefix]]
	set tree [slaveip_explicit_baseaddr $slave $intc $devicetype $params $baseaddr $highaddr $other_compatibles]
	set dcr_busif_handle [xget_hw_busif_handle $slave "SDCR"]
	if {[llength $dcr_busif_handle] != 0} {
		if {[bus_is_connected $slave "SDCR"] != 0} {
			# Hmm.. looks like there's a dcr interface.
			set tree [append_dcr_interface $tree $slave]
		}
	}
	return $tree
}

proc slaveip_explicit_baseaddr {slave intc devicetype params baseaddr highaddr {other_compatibles {}} } {
	set name [xget_hw_name $slave]
	set type [xget_hw_value $slave]
	if {$devicetype == ""} {
		set devicetype $type
	}
	set tree [slaveip_basic $slave $intc $params [format_ip_name $devicetype $baseaddr $name] $other_compatibles]
	return [tree_append $tree [gen_reg_property $name $baseaddr $highaddr]]
}

proc slaveip_basic {slave intc params nodename {other_compatibles {}} } {
	set name [xget_hw_name $slave]
	set type [xget_hw_value $slave]

	set hw_ver [xget_hw_parameter_value $slave "HW_VER"]

	set ip_node {}
	lappend ip_node [gen_compatible_property $name $type $hw_ver $other_compatibles]

	# Generate the parameters
	set ip_node [gen_params $ip_node $slave $params]

	return [list $nodename tree $ip_node]
}

proc gen_intc {slave intc devicetype param} {
	set tree [slaveip $slave $intc $devicetype $param]
	set intc_name [lindex $tree 0]
	set intc_node [lindex $tree 2]

	# Tack on the interrupt-specific tags.
	lappend intc_node [list \#interrupt-cells hexint 2]
	lappend intc_node [list interrupt-controller empty empty]
	return [list $intc_name tree $intc_node]
}

# Generate a slaveip, assuming it is inside a compound that has a
# baseaddress and reasonable ranges.
# index: The index of this slave
# stride: The distance between instances of the slave inside the container
# size: The size of the address space for the slave
proc slaveip_in_compound_intr {slave intc interrupt_port_list devicetype parameter_list index stride size} {
	set name [xget_hw_name $slave]
	set type [xget_hw_value $slave]
	if {$devicetype == ""} {
		set devicetype $type
	}
	set baseaddr [expr $index * $stride]
	set highaddr [expr $baseaddr + $size - 1]
	set ip_tree [slaveip_basic $slave $intc $parameter_list [format_ip_name $devicetype $baseaddr]]
	set ip_tree [tree_append $ip_tree [gen_reg_property $name $baseaddr $highaddr]]
	set ip_tree [gen_interrupt_property $ip_tree $slave $intc $interrupt_port_list]
	return $ip_tree
}

proc slave_s2imac_epc {slave intc} {
	set name [xget_hw_name $slave]
	set baseaddr [scan_int_parameter_value $slave "C_PRH0_BASEADDR"]
	set highaddr [scan_int_parameter_value $slave "C_PRH0_HIGHADDR"]

	# Add this temac channel to the alias list
	variable ethernet_count
	variable alias_node_list
	lappend alias_node_list [list ethernet$ethernet_count aliasref $name $ethernet_count]
	incr ethernet_count

	# 'network' type
	set ip_tree [slaveip_basic $slave $intc [default_parameters $slave] [format_ip_name "ethernet" $baseaddr $name] "s2i,s2imac-epc"]
	set ip_tree [tree_append $tree [list "device_type" string "network"]]
	set ip_tree [gen_macaddr $ip_tree]

	# epc slot 0..3
	set subnode [gen_reg_property $name $baseaddr $highaddr]
	for {set x 1} {$x < 5} {incr x} {
		if {[parameter_exists $slave [format "C_PRH%i_BASEADDR" $x]]} {
			set baseaddr [scan_int_parameter_value $slave [format "C_PRH%i_BASEADDR" $x]]
			set highaddr [scan_int_parameter_value $slave [format "C_PRH%i_HIGHADDR" $x]]
			if {![string match "0x[format %x $baseaddr]" "0xffffffff"]} {
				set subnode [reg_property_append $subnode [gen_reg_property $name $baseaddr $highaddr]]
			}
		}
	}
	set ip_tree [tree_append $tree $subnode]

	set ip_tree [gen_interrupt_property $tree $slave $intc [interrupt_list $slave]]

	return $ip_tree
}

proc ll_temac_parameters {ip_handle index} {
	set params {}
	foreach param [default_parameters $ip_handle] {
		set pattern [format "C_TEMAC%d*" $index]
		if {[string match $pattern $param]} {
			lappend params $param
		}
	}
	return $params
}

proc slave_ll_temac_port {slave intc index} {
	set name [xget_hw_name $slave]
	set type [xget_hw_value $slave]
	set baseaddr [scan_int_parameter_value $slave "C_BASEADDR"]
	set baseaddr [expr $baseaddr + $index * 0x40]
	set highaddr [expr $baseaddr + 0x3f]

	# Add this temac channel to the alias list
	variable ethernet_count
	variable alias_node_list
	lappend alias_node_list [list ethernet$ethernet_count aliasref $name $ethernet_count]
	incr ethernet_count

	set ip_tree [slaveip_basic $slave $intc "" [format_ip_name "ethernet" $baseaddr]]
	set ip_tree [tree_append $ip_tree [list "device_type" string "network"]]
	set ip_tree [gen_macaddr $ip_tree]
	variable phy_count
	set ip_tree [tree_append $ip_tree [list "phy-handle" labelref phy$phy_count]]

	set ip_tree [tree_append $ip_tree [gen_reg_property $name $baseaddr $highaddr]]
	set ip_tree [gen_interrupt_property $ip_tree $slave $intc [format "TemacIntc%d_Irpt" $index]]
	set ip_name [lindex $ip_tree 0]
	set ip_node [lindex $ip_tree 2]
	# Generate the parameters, stripping off the right prefix.
	set ip_node [gen_params $ip_node $slave [ll_temac_parameters $slave $index] [format "C_TEMAC%i_" $index]]
	# Generate the common parameters.
	set ip_node [gen_params $ip_node $slave [list "C_PHY_TYPE" "C_TEMAC_TYPE" "C_BUS2CORE_CLK_RATIO"]]
	set ip_tree [list $ip_name tree $ip_node]
	set mhs_handle [xget_hw_parent_handle $slave]
	# See what the temac is connected to.
	set ll_busif_handle [xget_hw_busif_handle $slave "LLINK$index"]
	set ll_name [xget_hw_value $ll_busif_handle]
	set ll_ip_handle [xget_hw_connected_busifs_handle $mhs_handle $ll_name "target"]
	set ll_ip_handle_name [xget_hw_name $ll_ip_handle]
	set connected_ip_handle [xget_hw_parent_handle $ll_ip_handle]
	set connected_ip_name [xget_hw_name $connected_ip_handle]
	set connected_ip_type [xget_hw_value $connected_ip_handle]
	if {$connected_ip_type == "mpmc"} {
		# Assumes only one MPMC.
		if {[string match SDMA_LL? $ll_ip_handle_name]} {
			set port_number [string range $ll_ip_handle_name 7 7]
			set sdma_name "PIM$port_number"
			set ip_tree [tree_append $ip_tree [list "llink-connected" labelref $sdma_name]]
		} else {
			error "found ll_temac connected to mpmc, but can't find the port number!"
		}
	} elseif {$connected_ip_type == "ppc440_virtex5"} {
		# Assumes only one PPC.
		if {[string match LLDMA? $ll_ip_handle_name]} {
			set port_number [string range $ll_ip_handle_name 5 5]
			set sdma_name "DMA$port_number"
			set ip_tree [tree_append $ip_tree [list "llink-connected" labelref $sdma_name]]
		} else {
			error "found ll_temac connected to ppc440_virtex5, but can't find the port number!"
		}
	} else {
		# Hope it's something that only has one locallink
		# connection. Most likely an xps_ll_fifo
		set ip_tree [tree_append $ip_tree [list "llink-connected" labelref "$connected_ip_name"]]
	}
	set ip_tree [tree_append $ip_tree [gen_mdiotree $slave $intc]]
	return $ip_tree
}

proc slave_ll_temac {slave intc} {
	set tree [compound_slave $slave]
	set tree [tree_append $tree [list ranges empty empty]]
	set tree [tree_append $tree [slave_ll_temac_port $slave $intc 0] ]
	set port1_enabled  [scan_int_parameter_value $slave "C_TEMAC1_ENABLED"]
	if {$port1_enabled == "1"} {
		set tree [tree_append $tree [slave_ll_temac_port $slave $intc 1] ]
	}
	return $tree
}

proc slave_mpmc {slave intc} {
	set share_addresses [scan_int_parameter_value $slave "C_ALL_PIMS_SHARE_ADDRESSES"]
	if {[catch {
		# Found control port for ECC and performance monitors
		set tree [slaveip $slave $intc "" "" "MPMC_CTRL_"]
		set ip_name [lindex $tree 0]
		set mpmc_node [lindex $tree 2]
	}]} {
		# No control port
		if {$share_addresses == 0} {
			set baseaddr [scan_int_parameter_value $slave "C_PIM0_BASEADDR"]
		} else {
			set baseaddr [scan_int_parameter_value $slave "C_MPMC_BASEADDR"]
		}
		set tree [slaveip_basic $slave $intc "" [format_ip_name "mpmc" $baseaddr] ]
		set ip_name [lindex $tree 0]
		set mpmc_node [lindex $tree 2]

		# Generate the parameters
		# set mpmc_node [gen_params $mpmc_node $slave [default_parameters $slave] ]

	}
	lappend mpmc_node [list \#size-cells int 1]
	lappend mpmc_node [list \#address-cells int 1]
	lappend mpmc_node [list ranges empty empty]

	set num_ports [scan_int_parameter_value $slave "C_NUM_PORTS"]
	for {set x 0} {$x < $num_ports} {incr x} {
		set pim_type [scan_int_parameter_value $slave [format "C_PIM%d_BASETYPE" $x]]
		if {$pim_type == 3} {
			# Found an SDMA port
			if {$share_addresses == 0} {
				set baseaddr [scan_int_parameter_value $slave [format "C_SDMA_CTRL%d_BASEADDR" $x]]
				set highaddr [scan_int_parameter_value $slave [format "C_SDMA_CTRL%d_HIGHADDR" $x]]
			} else {
				set baseaddr [scan_int_parameter_value $slave "C_SDMA_CTRL_BASEADDR"]
				set baseaddr [expr $baseaddr + $x * 0x80]
				set highaddr [expr $baseaddr + 0x7f]
			}

			set sdma_name [format_ip_name sdma $baseaddr "PIM$x"]
			set sdma_tree [list $sdma_name tree {}]
			set sdma_tree [tree_append $sdma_tree [gen_reg_property $sdma_name $baseaddr $highaddr]]
			set sdma_tree [tree_append $sdma_tree [gen_compatible_property $sdma_name "ll_dma" "1.00.a"]]
			set sdma_tree [gen_interrupt_property $sdma_tree $slave $intc [list [format "SDMA%d_Rx_IntOut" $x] [format "SDMA%d_Tx_IntOut" $x]]]

			lappend mpmc_node $sdma_tree

		}
	}
	return [list $ip_name tree $mpmc_node]
}

#get handle to interrupt controller from CPU handle
proc get_handle_to_intc {proc_handle port_name} {
	#one CPU handle
	set hwproc_handle [xget_handle $proc_handle "IPINST"]
	#hangle to mhs file
	set mhs_handle [xget_hw_parent_handle $hwproc_handle]
	#get handle to interrupt port on Microblaze
	set intr_port [xget_value $hwproc_handle "PORT" $port_name]
	if { [llength $intr_port] == 0 } {
		error "CPU has not connection to Interrupt controller"
	}
	#	set sink_port [xget_hw_connected_ports_handle $mhs_handle $intr_port "sink"]
	#	set sink_name [xget_hw_name $sink_port]
	#get source port periphery handle - on interrupt controller
	set source_port [xget_hw_connected_ports_handle $mhs_handle $intr_port "source"]
	#get interrupt controller handle
	set intc [xget_hw_parent_handle $source_port]
	set name [xget_hw_name $intc]
	debug handles "Interrupt Controller: $name $intc"
	return $intc
}

#return number of tabulator
proc tt {number} {
	set tab ""
	for {set x 0} {$x < $number} {incr x} {
		set tab "$tab\t"
	}
	return $tab
}

# Change the name of a node.
proc change_nodename {nodetochange oldname newname} {
	if {[llength $nodetochange] == 0} {
		error "Tried to change the name of an empty node: $oldname with $newname"
	}
	# The name of a node is in the first element of the node
	set lineofname [lindex $nodetochange 0]
	set substart [string first $oldname $lineofname]
	set subend [expr {$substart + [string length $oldname] - 1}]
	set lineofname [string replace $lineofname $substart $subend $newname]
	return [lreplace $nodetochange 0 0 "$lineofname"]
}

proc gener_slave {node slave intc} {
	set name [xget_hw_name $slave]
	set type [xget_hw_value $slave]
	switch -exact $type {
		"axi_intc" -
		"xps_intc" -
		"opb_intc" {
			# Interrupt controllers
			lappend node [gen_intc $slave $intc "interrupt-controller" "C_NUM_INTR_INPUTS C_KIND_OF_INTR"]
		}
		"mdm" -
		"opb_mdm" {
			# Check if interrupt line is setup - if not then can't be used as console
			set port_handle [xget_hw_port_handle $slave [interrupt_list $slave]]
			set interrupt_signal [xget_value $port_handle "VALUE"]
			if {[llength "$interrupt_signal"] != 0} {
				variable serial_count
				variable uartlite_count
				variable alias_node_list
				lappend alias_node_list [list serial$serial_count aliasref $name $uartlite_count]
				incr serial_count
				incr uartlite_count
			}

			# Microblaze debug
			# EDK 11.4 disables PLB connection when USE_UART is disabled that's why whole node won't be generated
			# Only bus connected IPs are generated
			lappend node [slaveip_intr $slave $intc [interrupt_list $slave] "debug" [default_parameters $slave] "" "" "xlnx,xps-uartlite-1.00.a" ]
			#"C_MB_DBG_PORTS C_UART_WIDTH C_USE_UART"]
		}
		"axi_uartlite" -
		"xps_uartlite" -
		"opb_uartlite" {
			# Add this uartlite device to the alias list
			variable serial_count
			variable uartlite_count
			variable alias_node_list
			lappend alias_node_list [list serial$serial_count aliasref $name $uartlite_count]
			incr serial_count

			set ip_tree [slaveip_intr $slave $intc [interrupt_list $slave] "serial" [default_parameters $slave] ]
			set ip_tree [tree_append $ip_tree [list "device_type" string "serial"]]
			set ip_tree [tree_append $ip_tree [list "port-number" int $uartlite_count]]
			set ip_tree [tree_append $ip_tree [list "current-speed" int [xget_sw_parameter_value $slave "C_BAUDRATE"]]]
			if { $type == "opb_uartlite"} {
				set ip_tree [tree_append $ip_tree [list "clock-frequency" int [get_clock_frequency $slave "SOPB_Clk"]]]
			} elseif { $type == "xps_uartlite" } {
				set ip_tree [tree_append $ip_tree [list "clock-frequency" int [get_clock_frequency $slave "SPLB_Clk"]]]
			} elseif { $type == "axi_uartlite" } {
				set ip_tree [tree_append $ip_tree [list "clock-frequency" int [get_clock_frequency $slave "S_AXI_ACLK"]]]
			}
			incr uartlite_count
			lappend node $ip_tree
			#"BAUDRATE DATA_BITS CLK_FREQ ODD_PARITY USE_PARITY"]
		}
		"axi_uart16550" -
		"xps_uart16550" -
		"plb_uart16550" -
		"opb_uart16550" {
			# Add this uart device to the alias list
			variable serial_count
			variable uart16550_count
			variable alias_node_list
			lappend alias_node_list [list serial$serial_count aliasref $name $uart16550_count]
			incr serial_count
			incr uart16550_count

			set ip_tree [slaveip_intr $slave $intc [interrupt_list $slave] "serial" [default_parameters $slave] "" "" [list "ns16550a"] ]
			set ip_tree [tree_append $ip_tree [list "device_type" string "serial"]]
			set ip_tree [tree_append $ip_tree [list "current-speed" int "9600"]]

			# The 16550 cores usually use the bus clock as the baud
			# reference, but can also take an external reference clock.
			if { $type == "opb_uart16550"} {
				set freq [get_clock_frequency $slave "OPB_Clk"]
			} elseif { $type == "plb_uart16550"} {
				set freq [get_clock_frequency $slave "PLB_Clk"]
			} elseif { $type == "xps_uart16550"} {
				set freq [get_clock_frequency $slave "SPLB_Clk"]
			} elseif { $type == "axi_uart16550"} {
				set freq [get_clock_frequency $slave "S_AXI_ACLK"]
			}
			set has_xin [scan_int_parameter_value $slave "C_HAS_EXTERNAL_XIN"]
			if { $has_xin == "1" } {
				set freq [get_clock_frequency $slave "xin"]
			}
			set ip_tree [tree_append $ip_tree [list "clock-frequency" int $freq]]

			set ip_tree [tree_append $ip_tree [list "reg-shift" int "2"]]
			if { $type == "axi_uart16550"} {
				set ip_tree [tree_append $ip_tree [list "reg-offset" hexint [expr 0x1000]]]
			} else {
				set ip_tree [tree_append $ip_tree [list "reg-offset" hexint [expr 0x1003]]]
			}
			lappend node $ip_tree
			#"BAUDRATE DATA_BITS CLK_FREQ ODD_PARITY USE_PARITY"]
		}
		"axi_timer" -
		"xps_timer" -
		"opb_timer" {
			global timer
			if {[ string match -nocase $name $timer ]} {
				set ip_tree [slaveip_intr $slave $intc [interrupt_list $slave] "system_timer" [default_parameters $slave] ]
				set one_timer_only [xget_hw_parameter_value $slave "C_ONE_TIMER_ONLY"]
				if { $one_timer_only == "1" } {
					debug warning "ERROR: Linux requires dual channel timer, but $name is set to single channel. Please configure the $name to dual channel"
					exit 1
				}
			} else {
				set ip_tree [slaveip_intr $slave $intc [interrupt_list $slave] "timer" [default_parameters $slave] ]
			}

			# for version 1.01b of the xps timer, make sure that it has the patch applied to the h/w
			# so that it's using an edge interrupt rather than a falling as described in AR 33880
			# this is tracking a h/w bug in EDK 11.4 that should be fixed in the future
 
			set hw_ver [xget_hw_parameter_value $slave "HW_VER"]
			if { $hw_ver == "1.01.b" && $type == "xps_timer" } {
				set port_handle [xget_hw_port_handle $slave "Interrupt"]
				set sensitivity [xget_hw_subproperty_value $port_handle "SENSITIVITY"];
				if { [string compare -nocase $sensitivity "EDGE_RISING"] != 0 } {
					error "xps_timer version 1.01b must be patched to rising edge IRQ sensitivity. \
						Please see Xilinx Answer Record 33880 at http://www.xilinx.com/support/answers/33880.htm \
						and follow the instructions there."
				}
			}
			#"C_COUNT_WIDTH C_ONE_TIMER_ONLY"]

			if { $type == "axi_timer"} {
				set freq [get_clock_frequency $slave "S_AXI_ACLK"]
				set ip_tree [tree_append $ip_tree [list "clock-frequency" int $freq]]
			}
			lappend node $ip_tree
		}
		"axi_sysace" -
		"xps_sysace" -
		"opb_sysace" {
			set ip_tree [slaveip_intr $slave $intc [interrupt_list $slave] "sysace" [default_parameters $slave] ]
			#"MEM_WIDTH"]
			set sysace_width [xget_hw_parameter_value $slave "C_MEM_WIDTH"]
			if { $sysace_width == "8" } {
				set ip_tree [tree_append $ip_tree [list "8-bit" empty empty]]
			} elseif { $sysace_width == "16" } {
				set ip_tree [tree_append $ip_tree [list "16-bit" empty empty]]
			} else {
				error "Unsuported Systemace memory width"
			}
			lappend node $ip_tree
		}
		"plb_ethernet" -
		"opb_ethernet" -
		"axi_ethernetlite" -
		"xps_ethernetlite" -
		"opb_ethernetlite" -
		"plb_temac" {
			# Add this temac channel to the alias list
			variable ethernet_count
			variable alias_node_list
			lappend alias_node_list [list ethernet$ethernet_count aliasref $name $ethernet_count]
			incr ethernet_count

			# 'network' type
			set ip_tree [slaveip_intr $slave $intc [interrupt_list $slave] "ethernet" [default_parameters $slave]]
			set ip_tree [tree_append $ip_tree [list "device_type" string "network"]]
			set ip_tree [gen_macaddr $ip_tree]

			if {$type == "xps_ethernetlite" || $type == "axi_ethernetlite"} {
				if {[parameter_exists $slave "C_INCLUDE_MDIO"]} {
					set has_mdio [scan_int_parameter_value $slave "C_INCLUDE_MDIO"]
					if {$has_mdio == 1} {
						variable phy_count
						set ip_tree [tree_append $ip_tree [list "phy-handle" labelref phy$phy_count]]
						set ip_tree [tree_append $ip_tree [gen_mdiotree $slave $intc]]
					}
				}
			}

			lappend node $ip_tree
		}
		"xps_ll_temac" {
			# We need to handle this specially, to notify the driver
			# about the connected LL connection, and the dual cores.
			lappend node [slave_ll_temac $slave $intc]
		}
		"s2imac_epc" {
			# We need to handle this specially, to notify the driver
			# about the connected S2IMAC connection, and the dual cores.
			lappend node [slave_s2imac_epc $slave $intc]
		}
		"axi_ethernet" {
			set name [xget_hw_name $slave]
			set type [xget_hw_value $slave]
			set baseaddr [scan_int_parameter_value $slave "C_BASEADDR"]
			set highaddr [expr $baseaddr + 0x3ffff]

			variable ethernet_count
			variable alias_node_list
			lappend alias_node_list [list ethernet$ethernet_count aliasref $name $ethernet_count]
			incr ethernet_count

			set ip_tree [slaveip_basic $slave $intc "" [format_ip_name "axi-ethernet" $baseaddr $name]]
			set ip_tree [tree_append $ip_tree [list "device_type" string "network"]]
			set ip_tree [gen_macaddr $ip_tree]
			variable phy_count
			set ip_tree [tree_append $ip_tree [list "phy-handle" labelref phy$phy_count]]

			set ip_tree [tree_append $ip_tree [gen_reg_property $name $baseaddr $highaddr]]
			set ip_tree [gen_interrupt_property $ip_tree $slave $intc [format "INTERRUPT"]]
			set ip_name [lindex $ip_tree 0]
			set ip_node [lindex $ip_tree 2]

			# Generate the common parameters.
			set ip_node [gen_params $ip_node $slave [list "C_PHY_TYPE" "C_TYPE" "C_PHYADDR" "C_INCLUDE_IO" "C_HALFDUP"]]
			set ip_node [gen_params $ip_node $slave [list "C_TXMEM" "C_RXMEM" "C_TXCSUM" "C_RXCSUM" "C_MCAST_EXTEND" "C_STATS" "C_AVB"]]
			set ip_node [gen_params $ip_node $slave [list "C_TXVLAN_TRAN" "C_RXVLAN_TRAN" "C_TXVLAN_TAG" "C_RXVLAN_TAG" "C_TXVLAN_STRP" "C_RXVLAN_STRP"]]
			set ip_tree [list $ip_name tree $ip_node]
			set mhs_handle [xget_hw_parent_handle $slave]

			# See what the axi ethernet is connected to.
			set axiethernet_busif_handle [xget_hw_busif_handle $slave "AXI_STR_TXD"]
			set axiethernet_name [xget_hw_value $axiethernet_busif_handle]
			set axiethernet_ip_handle [xget_hw_connected_busifs_handle $mhs_handle $axiethernet_name "INITIATOR"]
			set axiethernet_ip_handle_name [xget_hw_name $axiethernet_ip_handle]
			set connected_ip_handle [xget_hw_parent_handle $axiethernet_ip_handle]
			set connected_ip_name [xget_hw_name $connected_ip_handle]
			set connected_ip_type [xget_hw_value $connected_ip_handle]
			set ip_tree [tree_append $ip_tree [list "axistream-connected" labelref $connected_ip_name]]

			set ip_tree [tree_append $ip_tree [gen_mdiotree $slave $intc]]

			lappend node $ip_tree
		}
		"axi_dma" {
			set axiethernetfound 0
			set xdma "axi-dma"
			set mhs_handle [xget_hw_parent_handle $slave]
			set axidma_busif_handle [xget_hw_busif_handle $slave "M_AXIS_MM2S"]
			set axidma_name [xget_hw_value $axidma_busif_handle]
			set axidma_ip_handle [xget_hw_connected_busifs_handle $mhs_handle $axidma_name "TARGET"]
			set axidma_ip_handle_name [xget_hw_name $axidma_ip_handle]
			set connected_ip_handle [xget_hw_parent_handle $axidma_ip_handle]
			set connected_ip_name [xget_hw_name $connected_ip_handle]
			set connected_ip_type [xget_hw_value $connected_ip_handle]
			if {[string compare $connected_ip_type "axi_ethernet"] == 0} {
				set axiethernetfound 1
			}
			if {$axiethernetfound != 1} {
				set hw_name [xget_hw_name $slave]

				set baseaddr [scan_int_parameter_value $slave "C_BASEADDR"]
				set highaddr [scan_int_parameter_value $slave "C_HIGHADDR"]

				set mytree [list [format_ip_name "axidma" $baseaddr $hw_name] tree {}]

				set tx_chan [scan_int_parameter_value $slave "C_INCLUDE_MM2S"]
				if {$tx_chan == 1} {
					set chantree [dma_channel_config $xdma $baseaddr "MM2S" $intc $slave]
					set mytree [tree_append $mytree $chantree]
				}

				set rx_chan [scan_int_parameter_value $slave "C_INCLUDE_S2MM"]
				if {$rx_chan == 1} {
					set chantree [dma_channel_config $xdma [expr $baseaddr + 0x30] "S2MM" $intc $slave]
					set mytree [tree_append $mytree $chantree]
				}

				set mytree [tree_append $mytree [list \#size-cells int 1]]
				set mytree [tree_append $mytree [list \#address-cells int 1]]
				set mytree [tree_append $mytree [list compatible stringtuple [list "xlnx,axi-dma"]]]

				set stsctrl 1
				set sgdmamode1 1
				set sgdmamode [xget_hw_parameter_handle $slave "C_INCLUDE_SG"]
				if {$sgdmamode != ""} {
					set sgdmamode1 [scan_int_parameter_value $slave "C_INCLUDE_SG"]
					if {$sgdmamode1 == 0} {
						set stsctrl 0
						set mytree [tree_append $mytree [list "xlnx,sg-include-stscntrl-strm" hexint $stsctrl]]
					} else {
						set stsctrl [xget_hw_parameter_handle $slave "C_SG_INCLUDE_STSCNTRL_STRM"]
						if {$stsctrl != ""} {
							set stsctrl [scan_int_parameter_value $slave "C_SG_INCLUDE_STSCNTRL_STRM"]
						} else {
							set stsctrl 0
						}
						set mytree [tree_append $mytree [list "xlnx,sg-include-stscntrl-strm" hexint $stsctrl]]
					}
				} else {
					set stsctrl [xget_hw_parameter_handle $slave "C_SG_INCLUDE_STSCNTRL_STRM"]
					if {$stsctrl != ""} {
						set stsctrl [scan_int_parameter_value $slave "C_SG_INCLUDE_STSCNTRL_STRM"]
					} else {
						set stsctrl 0
					}
					set mytree [tree_append $mytree [list "xlnx,sg-include-stscntrl-strm" hexint $stsctrl]]
				}
				set mytree [tree_append $mytree [gen_ranges_property $slave $baseaddr $highaddr $baseaddr]]
				set mytree [tree_append $mytree [gen_reg_property $hw_name $baseaddr $highaddr]]

				lappend node $mytree
			}

			if {$axiethernetfound == 1} {
				if {[catch {lappend node [slaveip_intr $slave $intc [interrupt_list $slave] "" [default_parameters $slave] "" ]} {error}]} {
					debug warning $error
				}
			}
		}
		"axi_vdma" {
			set xdma "axi-vdma"
			set hw_name [xget_hw_name $slave]

			set baseaddr [scan_int_parameter_value $slave "C_BASEADDR"]
			set highaddr [scan_int_parameter_value $slave "C_HIGHADDR"]

			set mytree [list [format_ip_name "axivdma" $baseaddr $hw_name] tree {}]
			set tx_chan [scan_int_parameter_value $slave "C_INCLUDE_MM2S"]
			if {$tx_chan == 1} {
				set chantree [dma_channel_config $xdma $baseaddr "MM2S" $intc $slave]
				set mytree [tree_append $mytree $chantree]
			}

			set rx_chan [scan_int_parameter_value $slave "C_INCLUDE_S2MM"]
			if {$rx_chan == 1} {
				set chantree [dma_channel_config $xdma [expr $baseaddr + 0x30] "S2MM" $intc $slave]
				set mytree [tree_append $mytree $chantree]
			}

			set mytree [tree_append $mytree [list \#size-cells int 1]]
			set mytree [tree_append $mytree [list \#address-cells int 1]]
			set mytree [tree_append $mytree [list compatible stringtuple [list "xlnx,axi-vdma"]]]

			set tmp [xget_hw_parameter_handle $slave "C_INCLUDE_SG"]

			if {$tmp != ""} {
				set tmp [scan_int_parameter_value $slave "C_INCLUDE_SG"]
				set mytree [tree_append $mytree [list "xlnx,include-sg" hexint $tmp]]
			} else {
				# older core always has SG
				set mytree [tree_append $mytree [list "xlnx,include-sg" hexint 1]]
			}

			set tmp [scan_int_parameter_value $slave "C_NUM_FSTORES"]
			set mytree [tree_append $mytree [list "xlnx,num-fstores" hexint $tmp]]
			set mytree [tree_append $mytree [gen_ranges_property $slave $baseaddr $highaddr $baseaddr]]
			set mytree [tree_append $mytree [gen_reg_property $hw_name $baseaddr $highaddr]]

			lappend node $mytree
		}
		"axi_cdma" {
			set hw_name [xget_hw_name $slave]

			set baseaddr [scan_int_parameter_value $slave "C_BASEADDR"]
			set highaddr [scan_int_parameter_value $slave "C_HIGHADDR"]

			set mytree [list [format_ip_name "axicdma" $baseaddr $hw_name] tree {}]
			set namestring "dma-channel"
			set channame [format_name [format "%s@%x" $namestring $baseaddr]]

			set chan {}
			lappend chan [list compatible stringtuple [list "xlnx,axi-cdma-channel"]]
			set tmp [scan_int_parameter_value $slave "C_INCLUDE_DRE"]
			lappend chan [list "xlnx,include-dre" hexint $tmp]

			set tmp [scan_int_parameter_value $slave "C_USE_DATAMOVER_LITE"]
			lappend chan [list "xlnx,lite-mode" hexint $tmp]

			set tmp [scan_int_parameter_value $slave "C_M_AXI_DATA_WIDTH"]
			lappend chan [list "xlnx,datawidth" hexint $tmp]

			set tmp [scan_int_parameter_value $slave "C_M_AXI_MAX_BURST_LEN"]
			lappend chan [list "xlnx,max-burst-len" hexint $tmp]


			set chantree [list $channame tree $chan]
			set chantree [gen_interrupt_property $chantree $slave $intc [list "cdma_introut"]]

			set mytree [tree_append $mytree $chantree]

			set mytree [tree_append $mytree [list \#size-cells int 1]]
			set mytree [tree_append $mytree [list \#address-cells int 1]]
			set mytree [tree_append $mytree [list compatible stringtuple [list "xlnx,axi-cdma"]]]

			set tmp [scan_int_parameter_value $slave "C_INCLUDE_SG"]
			set mytree [tree_append $mytree [list "xlnx,include-sg" hexint $tmp]]

			set mytree [tree_append $mytree [gen_ranges_property $slave $baseaddr $highaddr $baseaddr]]
			set mytree [tree_append $mytree [gen_reg_property $hw_name $baseaddr $highaddr]]

			lappend node $mytree
		}
		"xps_tft" {
			lappend node [slaveip_dcr_or_plb $slave $intc "tft" [default_parameters $slave]]
		}
		"plb_tft_cntlr_ref" -
		"plb_dvi_cntlr_ref" {
			# We handle this specially, since it is a DCR slave.
			lappend node [slaveip_dcr $slave $intc "tft" [default_parameters $slave] "DCR_"]
		}
		"opb_ps2_dual_ref" {
			# We handle this specially, to report the two independent
			# ports.
			set tree [compound_slave $slave]
			set baseaddr [scan_int_parameter_value $slave "C_BASEADDR"]
			set highaddr [scan_int_parameter_value $slave "C_HIGHADDR"]
			set tree [tree_append $tree [gen_ranges_property $slave $baseaddr $highaddr 0]]
			set tree [tree_append $tree [slaveip_in_compound_intr $slave $intc "Sys_Intr1" "ps2" "" 0 0x1000 0x40]]
			set tree [tree_append $tree [slaveip_in_compound_intr $slave $intc "Sys_Intr2" "ps2" "" 1 0x1000 0x40]]
			lappend node $tree
		}
		"xps_ps2" {
			set baseaddr [scan_int_parameter_value $slave "C_BASEADDR"]
			set highaddr [scan_int_parameter_value $slave "C_HIGHADDR"]
			set is_dual [scan_int_parameter_value $slave "C_IS_DUAL"]

			if {$is_dual == 1} {
				# We handle this specially, to report the two independent
				# ports.
				set tree [compound_slave $slave]
				set tree [tree_append $tree [gen_ranges_property $slave $baseaddr $highaddr 0]]
				set tree [tree_append $tree [slaveip_in_compound_intr $slave $intc "IP2INTC_Irpt_1" "ps2" "" 0 0x1000 0x40]]
				set tree [tree_append $tree [slaveip_in_compound_intr $slave $intc "IP2INTC_Irpt_2" "ps2" "" 1 0x1000 0x40]]
				lappend node $tree
			} else {
				lappend node [slaveip_intr $slave $intc "IP2INTC_Irpt_1" "ps2" ""]
			}
		}
		"opb_ac97_controller_ref" {
			# We should handle this specially, to report the two
			# interrupts in the right order.
			lappend node [slaveip_intr $slave $intc "Playback_Interrupt Record_Interrupt" "ac97" ""]
		}
		"axi_gpio" -
		"xps_gpio" -
		"opb_gpio" {
			# save gpio names and width for gpio reset code
			global gpio_names
			lappend gpio_names [list [xget_hw_name $slave] [scan_int_parameter_value $slave "C_GPIO_WIDTH"]]
			# We should handle this specially, to report two ports.
			set ip_tree [slaveip_intr $slave $intc [interrupt_list $slave] "gpio" [default_parameters $slave]]
			set ip_tree [tree_append $ip_tree [list "#gpio-cells" int "2"]]
			set ip_tree [tree_append $ip_tree [list "gpio-controller" empty empty]]
			lappend node $ip_tree
		}
		"axi_iic" -
		"xps_iic" -
		"opb_iic" {
			# TODO: We should handle this specially, to report two ports.
			set ip_tree [slaveip_intr $slave $intc [interrupt_list $slave] "i2c" [default_parameters $slave]]
			# If it is a I2C/RTC, we will add a RTC subnode to the I2C controller
			set ip_rtctree [rtc_iic $slave $intc]
			if { "$ip_rtctree" != "" } {
				# Add the address-cells and size-cells to make the DTC compiler stop outputing warning
				set ip_tree [tree_append $ip_tree [list "#address-cells" int "1"]]
				set ip_tree [tree_append $ip_tree [list "#size-cells" int "0"]]
				set ip_tree [tree_append $ip_tree $ip_rtctree]
			}
			lappend node $ip_tree
		}
		"xps_spi" -
		"axi_spi" -
		"axi_quad_spi" {
			# We will handle SPI FLASH here
			set tree [slaveip_intr $slave $intc [interrupt_list $slave] "spi" [default_parameters $slave] "" ]
			set sftree [flash_spi $slave $intc]
			if { "$sftree" != "" } {
				# Add the address-cells and size-cells to make the DTC compiler stop outputing warning
				set tree [tree_append $tree [list "#address-cells" int "1"]]
				set tree [tree_append $tree [list "#size-cells" int "0"]]
				set tree [tree_append $tree $sftree]
			}
			lappend node $tree
		}
		"xps_usb_host" {
			lappend node [slaveip_intr $slave $intc [interrupt_list $slave] "usb" [default_parameters $slave] "SPLB_" "" [list "usb-ehci"]]
		}
		"opb_cypress_usb" -
		"axi_bram_ctrl" -
		"plb_bram_if_cntlr" -
		"opb_bram_if_cntlr" -
		"plb_ddr2" -
		"plb_ddr" -
		"plb_sdram" -
		"opb_ddr" -
		"opb_sdram" -
		"mch_opb_ddr2" -
		"mch_opb_ddr" -
		"mch_opb_sdram" -
		"axi_s6_ddrx" -
		"axi_v6_ddrx" -
		"axi_7series_ddrx" -
		"ppc440mc_ddr2" {
			# Do nothing..  this is handled by the 'memory' special case.
		}
		"xps_mch_emc" -
		"plb_emc" -
		"opb_emc" -
		"mch_opb_emc" {
			global main_memory main_memory_bank
			# Handle flash memories with 'banks'. Generate one flash node
			# for each bank, if necessary.  If not connected to flash,
			# then do nothing.
			set count [scan_int_parameter_value $slave "C_NUM_BANKS_MEM"]
			if { [llength $count] == 0 } {
				set count 1
			}
			for {set x 0} {$x < $count} {incr x} {

				# Make sure we didn't already register this guy as the main memory.
				# see main handling in gen_memories
				if {[ string match -nocase $name $main_memory ] && $x == $main_memory_bank } {
					continue;
				}
				global flash_memory flash_memory_bank
				set baseaddr_prefix [format "MEM%d_" $x]
				set tree [slaveip_intr $slave $intc [interrupt_list $slave] "flash" [default_parameters $slave] $baseaddr_prefix "" "cfi-flash"]

				# Flash needs a bank-width attribute.
				set datawidth [scan_int_parameter_value $slave [format "C_%sWIDTH" $baseaddr_prefix]]
				set tree [tree_append $tree [list "bank-width" int "[expr ($datawidth/8)]"]]

				# If it is a set as the system Flash memory, change the name of this node to Linux standard system Flash emmory name
				if {[ string match -nocase $name $flash_memory ] && $x == $flash_memory_bank} {
					set tree [change_nodename $tree $name "primary_flash"]
				}
				lappend node $tree
			}
		}
		"axi_emc" {
			# Handle flash memories with 'banks'. Generate one flash node
			# for each bank, if necessary.  If not connected to flash,
			# then do nothing.
			set count [scan_int_parameter_value $slave "C_NUM_BANKS_MEM"]
			if { [llength $count] == 0 } {
				set count 1
			}
			for {set x 0} {$x < $count} {incr x} {
				set synch_mem [scan_int_parameter_value $slave [format "C_MEM%d_TYPE" $x]]
				# C_MEM$x_TYPE = 2 or 3 indicates the bank handles
				# a flash device and it should be listed as a
				# slave in fdt.
				# C_MEM$x_TYPE = 0, 1 or 4 indicates the bank handles
				# SRAM and it should be listed as a memory in
				# fdt.
				if { $synch_mem == 2 || $synch_mem == 3 } {
					set baseaddr_prefix [format "S_AXI_MEM%d_" $x]
					set tree [slaveip_intr $slave $intc [interrupt_list $slave] "flash" [default_parameters $slave] $baseaddr_prefix "" "cfi-flash"]

					# Flash needs a bank-width attribute.
					set datawidth [scan_int_parameter_value $slave [format "C_MEM%d_WIDTH" $x]]
					set tree [tree_append $tree [list "bank-width" int "[expr ($datawidth/8)]"]]

					# If it is a set as the system Flash memory, change the name of this node to Linux standard system Flash emmory name
					global flash_memory flash_memory_bank
					if {[ string match -nocase $name $flash_memory ] && $x == $flash_memory_bank} {
						set tree [change_nodename $tree $name "primary_flash"]
					}
					lappend node $tree
				}
			}
		}
		"mpmc" {
			# We should handle this specially, to report the DMA
			# ports.  This is a hack that happens to work for the
			# design I have.  Note that we don't use the default
			# parameters here because of the slew of parameters the
			# mpmc has.
			lappend node [slave_mpmc $slave $intc]
		}
		"opb2plb_bridge" {
			# Hmm.. how do we represent this?
			#	lappend node [bus_bridge $slave $intc "MPLB" "C_RNG"]
		}
		"plb2opb_bridge" -
		"plbv46_opb_bridge" {
			set baseaddr [scan_int_parameter_value $slave "C_RNG0_BASEADDR"]
			set tree [bus_bridge $slave $intc $baseaddr "MOPB"]
			set ranges_list [default_ranges $slave "C_NUM_ADDR_RNG" "C_RNG%d_BASEADDR" "C_RNG%d_HIGHADDR"]
			set tree [tree_append $tree [gen_ranges_property_list $slave $ranges_list]]
			lappend node $tree
		}
		"plbv46_plbv46_bridge" {
			# FIXME: multiple ranges!
			set baseaddr [scan_int_parameter_value $slave "C_RNG0_BASEADDR"]
			set tree [bus_bridge $slave $intc $baseaddr "MPLB"]
			set ranges_list [default_ranges $slave "C_NUM_ADDR_RNG" "C_RNG%d_BASEADDR" "C_RNG%d_HIGHADDR"]
			set tree [tree_append $tree [gen_ranges_property_list $slave $ranges_list]]
			lappend node $tree
		}
		"opb_opb_lite" {
			# FIXME: multiple ranges!
			set baseaddr [scan_int_parameter_value $slave "C_DEC0_BASEADDR"]
			set tree [bus_bridge $slave $intc $baseaddr "MOPB"]
			set ranges_list [default_ranges $slave "C_NUM_DECODES" "C_DEC%d_BASEADDR" "C_DEC%d_HIGHADDR"]
			set tree [tree_append $tree [gen_ranges_property_list $slave $ranges_list]]
			lappend node $tree
		}
		"opb2dcr_bridge" -
		"plbv46_dcr_bridge" {
			set baseaddr [scan_int_parameter_value $slave "C_BASEADDR"]
			set highaddr [scan_int_parameter_value $slave "C_HIGHADDR"]
			set slavetree [slaveip_intr $slave $intc [interrupt_list $slave] "" [default_parameters $slave] ""]
			set slavetree [tree_append $slavetree [list dcr-controller empty empty]]
			set slavetree [tree_append $slavetree [list dcr-access-method string mmio]]
			set slavetree [tree_append $slavetree [list dcr-mmio-stride int 4]]
			set slavetree [tree_append $slavetree [gen_reg_property $name $baseaddr $highaddr "dcr-mmio-range"]]
			lappend node $slavetree
			set tree [bus_bridge $slave $intc 0 "MDCR"]

			# Backward compatibility to not break older style tft driver
			# connected through opb2dcr bridge.
			set ranges [gen_ranges_property $slave $baseaddr $highaddr 0]
			set tree [tree_append $tree $ranges]

			lappend node $tree
		}
		"plbv46_pci" {
			# We can automatically generate the ranges property, but that's about it
			# the interrupt-map encodes board-level info that cannot be
			# derived from the MHS.
			# Default handling for all params first
			set ip_tree [slaveip_intr $slave $intc [interrupt_list $slave] "plbv46-pci" [default_parameters $slave]]

			# Standard stuff required fror the pci OF bindings
			set ip_tree [tree_append $ip_tree [list "#size-cells" int "2"]]
			set ip_tree [tree_append $ip_tree [list "#address-cells" int "3"]]
			set ip_tree [tree_append $ip_tree [list "#interrupt-cells" int "1"]]
			set ip_tree [tree_append $ip_tree [list "device_type" string "pci"]]
			# Generate ranges property.  Lots of assumptions here - 32 bit address space being the main one
			set ranges ""
			set ipifbar_num [ scan_int_parameter_value $slave "C_IPIFBAR_NUM"]
			for {set i 0} {$i < $ipifbar_num} {incr i} {
				set ipif_spacetype [ scan_int_parameter_value $slave [ format "C_IPIF_SPACETYPE_%i" $i ] ]
				set ipifbar [ scan_int_parameter_value $slave [ format "C_IPIFBAR_%i" $i ] ]
				set ipif_highaddr [ scan_int_parameter_value $slave [ format "C_IPIF_HIGHADDR_%i" $i ] ]
				set ipifbar2pcibar [ scan_int_parameter_value $slave [ format "C_IPIFBAR2PCIBAR_%i" $i ] ]
				# A quick DRC to make sure the IPIFBAR and IPIFBAR2PCIBAR match
				# This is a limitation of the kernel PCI layer rather than anything else
				if { $ipifbar != $ipifbar2pcibar } {
					debug warning "WARNING: $name:  C_IPIFBAR_$i and C_IPIBAR2PCIBAR_$i don't match"
				}
				# Different magic number depending upon the type of address space
				switch $ipif_spacetype {
					"0" {
						# IO space
						set space_code "0x01000000"
						debug warning "WARNING: $name BAR $i: PCI I/O spaces not supported in Linux kernel PCI drivers"
					}
					"1" {
						# mem space
						set space_code "0x02000000"
					}
				}
				set ranges [lappend ranges $space_code 0 $ipifbar2pcibar $ipifbar 0 [ expr $ipif_highaddr - $ipifbar + 1 ]]
			}
			set ip_tree [tree_append $ip_tree [ list "ranges" hexinttuple $ranges ]]

			# Now the interrupt-map-mask etc
			set ip_tree [tree_append $ip_tree [ list "interrupt-map-mask" hexinttuple "0xff00 0x0 0x0 0x7" ]]

			# Make sure the user knows they've still got more work to do
			# If we were prepared to add a custom PARAMETER to the MLD then we could do more here, but for now this is
			# the best we can do
			debug warning "WARNING: Cannot automatically populate PCI interrupt-map property - this must be completed manually"
			lappend node $ip_tree
		}
		"axi2axi_connector" {
			# FIXME: multiple ranges!
			set baseaddr [scan_int_parameter_value $slave "C_S_AXI_RNG00_BASEADDR"]
			set tree [bus_bridge $slave $intc $baseaddr "M_AXI"]
			lappend node $tree
		}
		"microblaze" {
			debug ip "Other Microblaze CPU $name=$type"
			lappend node [gen_microblaze $slave [default_parameters $slave]]
		}
		"ppc405" {
			debug ip "Other PowerPC405 CPU $name=$type"
			lappend node [gen_ppc405 $slave [default_parameters $slave]]
		}
		"xps_epc" {
			set tree [compound_slave $slave "C_PRH0_BASEADDR"]
			set tree [tree_append $tree [list ranges empty empty]]

			set epc_peripheral_num [xget_hw_parameter_value $slave "C_NUM_PERIPHERALS"]
			for {set x 0} {$x < ${epc_peripheral_num}} {incr x} {
				set subnode [slaveip_intr $slave $intc [interrupt_list $slave] "" [default_parameters $slave] [format "PRH%i_" $x]]
				set subnode [change_nodename $subnode $name "${name}_p${x}"]
				set tree [tree_append $tree $subnode]
			}
			lappend node $tree
		}
		default {
			set dtype ""
			set compat ""
			global generic_uio_list
			foreach generic_uio $generic_uio_list {
				if {[string match $name $generic_uio]} {
					# We should handle this specially, to make it compatible to generic-uio.
					set dtype "uio"
					set compat "generic-uio"
				}
			}
			# Decide if we have to handle a AXI/nonAXI slave w or w/o MBAR.
			if {[parameter_exists $slave "C_MEM0_BASEADDR"]} {
				set mbnstr "C_MEM"
			} elseif {[parameter_exists $slave "C_S_AXI_MEM0_BASEADDR"]} {
				set mbnstr "C_S_AXI_MEM"
			} else {
				set mbnstr ""
			}
			# *Most* IP with or w/o MBARS should be handled by this default case.
			if {[parameter_exists $slave "C_BASEADDR"] && [parameter_exists $slave [format "%s0_BASEADDR" $mbnstr]]} {
				set baseaddr [scan_int_parameter_value $slave "C_BASEADDR"]
				set highaddr [scan_int_parameter_value $slave "C_HIGHADDR"]
				if {[catch {set tree [slaveip_basic $slave $intc [default_parameters $slave] [format_ip_name $dtype $baseaddr $name] $compat]} {error}]} {
					debug warning "Warning: Default slave handling for unknown IP $name ($type) Failed...  It won't show up in the device tree."
					debug warning $error
				} else {
					set subnode [gen_reg_property $name $baseaddr $highaddr]
					for {set x 0} {$x < 8} {incr x} {
						if {[parameter_exists $slave [format "%s%i_BASEADDR" $mbnstr $x]]} {
							set baseaddr [scan_int_parameter_value $slave [format "%s%i_BASEADDR" $mbnstr $x]]
							set highaddr [scan_int_parameter_value $slave [format "%s%i_HIGHADDR" $mbnstr $x]]
							if {[catch {set subnode [reg_property_append $subnode [gen_reg_property $name $baseaddr $highaddr]]} {error}]} {
								debug warning "Warning: Default MBAR handling for unknown IP $name ($type) MEM$x Failed...  It won't show up in the device tree."
								debug warning $error
							}
						}
					}
					set tree [tree_append $tree $subnode]
					# TODO: gen_interrupt_property $tree $slave $intc [interrupt_list $slave]
					set tree [gen_interrupt_property $tree $slave $intc [interrupt_list $slave]]
				}
				lappend node $tree
			} elseif {[parameter_exists $slave [format "%s0_BASEADDR" $mbnstr]]} {
				set baseaddr [scan_int_parameter_value $slave [format "%s0_BASEADDR" $mbnstr]]
				set highaddr [scan_int_parameter_value $slave [format "%s0_HIGHADDR" $mbnstr]]
				if {[catch {set tree [slaveip_basic $slave $intc [default_parameters $slave] [format_ip_name $dtype $baseaddr $name] $compat]} {error}]} {
					debug warning "Warning: Default slave handling for unknown IP $name ($type) Failed...  It won't show up in the device tree."
					debug warning $error
				} else {
					set subnode [gen_reg_property $name $baseaddr $highaddr]
					for {set x 1} {$x < 8} {incr x} {
						if {[parameter_exists $slave [format "%s%i_BASEADDR" $mbnstr $x]]} {
							set baseaddr [scan_int_parameter_value $slave [format "%s%i_BASEADDR" $mbnstr $x]]
							set highaddr [scan_int_parameter_value $slave [format "%s%i_HIGHADDR" $mbnstr $x]]
							if {[catch {set subnode [reg_property_append $subnode [gen_reg_property $name $baseaddr $highaddr]]} {error}]} {
								debug warning "Warning: Default MBAR handling for unknown IP $name ($type) MEM$x Failed...  It won't show up in the device tree."
								debug warning $error
							}
						}
					}
					set tree [tree_append $tree $subnode]
					# TODO: gen_interrupt_property $tree $slave $intc [interrupt_list $slave]
					set tree [gen_interrupt_property $tree $slave $intc [interrupt_list $slave]]
				}
				lappend node $tree
			} elseif {[catch {lappend node [slaveip_intr $slave $intc [interrupt_list $slave] $dtype [default_parameters $slave] "" "" $compat]} {error}]} {
				debug warning "Warning: Default slave handling for unknown IP $name ($type) Failed...  It won't show up in the device tree."
				debug warning $error
			}
		}
	}
	return $node
}

proc memory {slave baseaddr_prefix params} {
	set name [xget_hw_name $slave]
	set type [xget_hw_value $slave]
	set par [xget_hw_parameter_handle $slave "*"]
	set hw_ver [xget_hw_parameter_value $slave "HW_VER"]

	set ip_node {}

	set baseaddr [scan_int_parameter_value $slave [format "C_%sBASEADDR" $baseaddr_prefix]]
	set highaddr [scan_int_parameter_value $slave [format "C_%sHIGHADDR" $baseaddr_prefix]]

	global main_memory main_memory_size
	if { [string match $name $main_memory] && $main_memory_size != 0 } {
		if { $main_memory_size < $highaddr - $baseaddr + 1 } {
			set highaddr [expr $baseaddr + $main_memory_size - 1]
		}
	}

	lappend ip_node [gen_reg_property $name $baseaddr $highaddr]
	lappend ip_node [list "device_type" string "memory"]
	set ip_node [gen_params $ip_node $slave $params]
	return [list [format_ip_name memory $baseaddr $name] tree $ip_node]
}

proc gen_ppc405 {tree hwproc_handle params} {
	set out ""
	variable cpunumber

	set cpu_name [xget_hw_name $hwproc_handle]
	set cpu_type [xget_hw_value $hwproc_handle]
	set hw_ver [xget_hw_parameter_value $hwproc_handle "HW_VER"]

	set cpus_node {}
	set proc_node {}
	lappend proc_node [list "device_type" string "cpu"]
	lappend proc_node [list model string "PowerPC,405"]
	lappend proc_node [list compatible stringtuple [list "PowerPC,405" "ibm,ppc405"]]

	# Get the clock frequency from the processor
	set clk [get_clock_frequency $hwproc_handle "CPMC405CLOCK"]
	if {$clk == ""} {
		set proc_handle [xget_libgen_proc_handle]
		set clk [xget_sw_parameter_value $proc_handle "CORE_CLOCK_FREQ_HZ"]
	}
	debug clock "Clock Frequency: $clk"

	lappend proc_node [list clock-frequency int $clk]
	# Assume that the CPMC405TIMERENABLE is always high, so the
	# timebase is the same as the processor clock.
	lappend proc_node [list timebase-frequency int $clk]
	lappend proc_node [list reg int $cpunumber]
	lappend proc_node [list i-cache-size hexint [expr 0x4000]]
	lappend proc_node [list i-cache-line-size hexint 32]
	lappend proc_node [list d-cache-size hexint [expr 0x4000]]
	lappend proc_node [list d-cache-line-size hexint 32]
	set proc_node [gen_params $proc_node $hwproc_handle $params]
	lappend proc_node [list dcr-controller empty empty]
	lappend proc_node [list dcr-access-method string native]

	lappend cpus_node [list [format_ip_name "cpu" $cpunumber $cpu_name] "tree" "$proc_node"]
	lappend cpus_node [list \#size-cells int 0]
	lappend cpus_node [list \#address-cells int 1]
	incr cpunumber
	lappend cpus_node [list \#cpus hexint "$cpunumber" ]
	lappend tree [list cpus tree "$cpus_node"]
	return $tree
}

proc gen_ppc440 {tree hwproc_handle intc params} {
	set out ""
	variable cpunumber

	set cpu_name [xget_hw_name $hwproc_handle]
	set cpu_type [xget_hw_value $hwproc_handle]
	set hw_ver [xget_hw_parameter_value $hwproc_handle "HW_VER"]

	set cpus_node {}
	set proc_node {}
	lappend proc_node [list "device_type" string "cpu"]
	lappend proc_node [list model string "PowerPC,440"]
	lappend proc_node [list compatible stringtuple [list "PowerPC,440" "ibm,ppc440"]]

	# Get the clock frequency from the processor
	set clk [get_clock_frequency $hwproc_handle "CPMC440CLK"]
	if {$clk == ""} {
		set proc_handle [xget_libgen_proc_handle]
		set clk [xget_sw_parameter_value $proc_handle "CORE_CLOCK_FREQ_HZ"]
	}
	debug clock "Clock Frequency: $clk"

	lappend proc_node [list clock-frequency int $clk]
	# Assume that the CPMC440TIMERENABLE is always high, so the
	# timebase is the same as the processor clock.
	lappend proc_node [list timebase-frequency int $clk]
	lappend proc_node [list reg int $cpunumber]
	lappend proc_node [list i-cache-size hexint [expr 0x8000]]
	lappend proc_node [list i-cache-line-size hexint 32]
	lappend proc_node [list d-cache-size hexint [expr 0x8000]]
	lappend proc_node [list d-cache-line-size hexint 32]
	set proc_node [gen_params $proc_node $hwproc_handle $params]
	lappend proc_node [list dcr-controller empty empty]
	lappend proc_node [list dcr-access-method string native]

	lappend proc_node [list \#size-cells int 1]
	lappend proc_node [list \#address-cells int 1]

	set num_ports [scan_int_parameter_value $hwproc_handle "C_NUM_DMA"]
	for {set x 0} {$x < $num_ports} {incr x} {
		set idcr_baseaddr [scan_int_parameter_value $hwproc_handle [format "C_IDCR_BASEADDR" $x]]
		# This expression comes out of the V5FX user guide.
		# 0x80, 0x98, 0xb0, 0xc8
		set baseaddr [expr $idcr_baseaddr + [expr 0x80 + 0x18*$x]]
		# Yes, apparently there really are 17 registers!
		set highaddr [expr $baseaddr + 0x10]

		set sdma_name [format_ip_name sdma $baseaddr "DMA$x"]
		set sdma_tree [list $sdma_name tree {}]
		set sdma_tree [tree_append $sdma_tree [gen_reg_property $sdma_name $baseaddr $highaddr "dcr-reg"]]
		set sdma_tree [tree_append $sdma_tree [gen_compatible_property $sdma_name "ll_dma" "1.00.a"]]
		set sdma_tree [gen_interrupt_property $sdma_tree $hwproc_handle $intc [list [format "DMA%dRXIRQ" $x] [format "DMA%dTXIRQ" $x]]]

		lappend proc_node $sdma_tree
	}

	lappend cpus_node [list [format_ip_name "cpu" $cpunumber $cpu_name] "tree" "$proc_node"]
	lappend cpus_node [list \#size-cells int 0]
	lappend cpus_node [list \#address-cells int 1]
	incr cpunumber
	lappend cpus_node [list \#cpus hexint "$cpunumber" ]
	lappend tree [list cpus tree "$cpus_node"]
	return $tree
}

proc gen_microblaze {tree hwproc_handle params} {
	set out ""
	variable cpunumber

	set cpu_name [xget_hw_name $hwproc_handle]
	set cpu_type [xget_hw_value $hwproc_handle]

	set icache_size [scan_int_parameter_value $hwproc_handle "C_CACHE_BYTE_SIZE"]
	set icache_base [scan_int_parameter_value $hwproc_handle "C_ICACHE_BASEADDR"]
	set icache_high [scan_int_parameter_value $hwproc_handle "C_ICACHE_HIGHADDR"]
	set dcache_size [scan_int_parameter_value $hwproc_handle "C_DCACHE_BYTE_SIZE"]
	set dcache_base [scan_int_parameter_value $hwproc_handle "C_DCACHE_BASEADDR"]
	set dcache_high [scan_int_parameter_value $hwproc_handle "C_DCACHE_HIGHADDR"]
	# The Microblaze parameters are in *words*, while the device tree
	# is in bytes.
	set icache_line_size [expr 4*[scan_int_parameter_value $hwproc_handle "C_ICACHE_LINE_LEN"]]
	set dcache_line_size [expr 4*[scan_int_parameter_value $hwproc_handle "C_DCACHE_LINE_LEN"]]
	set hw_ver [xget_hw_parameter_value $hwproc_handle "HW_VER"]

	global main_memory_size
	if { $main_memory_size != 0 } {
		if { $main_memory_size < $icache_high - $icache_base + 1 } {
			set icache_high [expr $icache_base + $main_memory_size - 1]
		}
		if { $main_memory_size < $dcache_high - $dcache_base + 1 } {
			set dcache_high [expr $dcache_base + $main_memory_size - 1]
		}
	}

	set cpus_node {}
	set proc_node {}
	lappend proc_node [list "device_type" string "cpu"]
	lappend proc_node [list model string "$cpu_type,$hw_ver"]
	lappend proc_node [gen_compatible_property $cpu_type $cpu_type $hw_ver]

	# Get the clock frequency from the processor
	set clk [get_clock_frequency $hwproc_handle "CLK"]
	debug clock "Clock Frequency: $clk"
	lappend proc_node [list clock-frequency int $clk]
	lappend proc_node [list timebase-frequency int $clk]
	lappend proc_node [list reg int 0]
	if { [llength $icache_size] != 0 } {
		lappend proc_node [list i-cache-baseaddr hexint $icache_base]
		lappend proc_node [list i-cache-highaddr hexint $icache_high]
		lappend proc_node [list i-cache-size hexint $icache_size]
		lappend proc_node [list i-cache-line-size hexint $icache_line_size]
	}
	if { [llength $dcache_size] != 0 } {
		lappend proc_node [list d-cache-baseaddr hexint $dcache_base]
		lappend proc_node [list d-cache-highaddr hexint $dcache_high]
		lappend proc_node [list d-cache-size hexint $dcache_size]
		lappend proc_node [list d-cache-line-size hexint $dcache_line_size]
	}

	#-----------------------------
	# generating additional parameters
	# the list of Microblaze parameters
	set proc_node [gen_params $proc_node $hwproc_handle $params]

	#-----------------------------
	lappend cpus_node [list [format_ip_name "cpu" $cpunumber  $cpu_name] "tree" "$proc_node"]
	lappend cpus_node [list \#size-cells int 0]
	lappend cpus_node [list \#address-cells int 1]
	incr cpunumber
	lappend cpus_node [list \#cpus hexint "$cpunumber" ]
	lappend tree [list cpus tree "$cpus_node"]
	return $tree
}

proc gen_memories {tree hwproc_handle} {
	global main_memory main_memory_bank
	set mhs_handle [xget_hw_parent_handle $hwproc_handle]
	set ip_handles [xget_hw_ipinst_handle $mhs_handle "*"]
	set memory_count 0
	foreach slave $ip_handles {
		set name [xget_hw_name $slave]
		set type [xget_hw_value $slave]
		if {![string match $name $main_memory]} {
			continue;
		}
		switch $type {
			"axi_bram_ctrl" -
			"plb_bram_if_cntlr" -
			"opb_bram_if_cntlr" {
				# Ignore these, since they aren't big enough to be main
				# memory, and we can't currently handle non-contiguous memory
				# regions.
			}
			"plb_sdram" -
			"opb_sdram" {
				# Handle bankless memories.
				lappend tree [memory $slave "" ""]
				incr memory_count
			}
			"ppc440mc_ddr2" {
				# Handle bankless memories.
				lappend tree [memory $slave "MEM_" ""]
				incr memory_count
			}
			"axi_s6_ddrx" {
				for {set x 0} {$x < 6} {incr x} {
					set baseaddr [scan_int_parameter_value $slave [format "C_S%d_AXI_BASEADDR" $x]]
					set highaddr [scan_int_parameter_value $slave [format "C_S%d_AXI_HIGHADDR" $x]]
					if {$highaddr < $baseaddr} {
						continue;
					}
					lappend tree [memory $slave [format "S%d_AXI_" $x] ""]
					break;
				}
				incr memory_count
			}
			"axi_v6_ddrx" -
			"axi_7series_ddrx" {
				lappend tree [memory $slave "S_AXI_" ""]
				incr memory_count
			}
			"opb_cypress_usb" -
			"plb_ddr2" -
			"plb_ddr" -
			"plb_sdram" -
			"opb_ddr" -
			"opb_sdram" -
			"mch_opb_ddr2" -
			"mch_opb_ddr" -
			"mch_opb_sdram" -
			"xps_mch_emc" -
			"plb_emc" -
			"opb_emc" -
			"mch_opb_emc" {
				# Handle memories with 'banks'. Generate one memory
				# node for each bank.
				set count [scan_int_parameter_value $slave "C_NUM_BANKS_MEM"]
				if { [llength $count] == 0 } {
					set count 1
				}
				for {set x 0} {$x < $count} {incr x} {
					if { $x == $main_memory_bank } {
						lappend tree [memory $slave [format "MEM%d_" $x] ""]
						incr memory_count
					}
				}
			}
			"axi_emc" {
				# Handle memories with 'banks'. Generate one memory
				# node for each bank.
				set count [scan_int_parameter_value $slave "C_NUM_BANKS_MEM"]
				if { [llength $count] == 0 } {
					set count 1
				}
				for {set x 0} {$x < $count} {incr x} {
					set synch_mem [scan_int_parameter_value $slave [format "C_MEM%d_TYPE" $x]]
					# C_MEM$x_TYPE = 2 or 3 indicates the bank handles
					# a flash device and it should be listed as a
					# slave in fdt.
					# C_MEM$x_TYPE = 0, 1 or 4 indicates the bank handles
					# SRAM and it should be listed as a memory in
					# fdt.
					if { {$synch_mem == 2} || {$synch_mem == 3} } {
						continue;
					}
					lappend tree [memory $slave [format "S_AXI_MEM%d_" $x] ""]
					incr memory_count
					if {[ string match -nocase $name $flash_memory ] && $x == $flash_memory_bank} {
						set tree [change_nodename $tree $name "primary_flash"]
					}
					lappend node $tree
				}
			}
			"mpmc" {
				set share_addresses [scan_int_parameter_value $slave "C_ALL_PIMS_SHARE_ADDRESSES"]
				if {$share_addresses != 0} {
					lappend tree [memory $slave "MPMC_" ""]
				} else {
					set old_baseaddr [scan_int_parameter_value $slave [format "C_PIM0_BASEADDR" $x]]
					set old_offset [scan_int_parameter_value $slave [format "C_PIM0_OFFSET" $x]]
					set safe_addresses 1
					set num_ports [scan_int_parameter_value $slave "C_NUM_PORTS"]
					for {set x 1} {$x < $num_ports} {incr x} {
						set baseaddr [scan_int_parameter_value $slave [format "C_PIM%d_BASEADDR" $x]]
						set baseaddr [scan_int_parameter_value $slave [format "C_PIM%d_OFFSET" $x]]
						if {$baseaddr != $old_baseaddr} {
							debug warning "Warning!: mpmc is configured with different baseaddresses on different ports!  Since this is a potentially hazardous configuration, a device tree node describing the memory will not be generated."
							set safe_addresses 0
						}
						if {$offset != $old_offset} {
							debug warning "Warning!: mpmc is configured with different offsets on different ports!  Since this is a potentially hazardous configuration, a device tree node describing the memory will not be generated."
						}
					}
					if {$safe_addresses == 1} {
						lappend tree [memory $slave "PIM0_" ""]
					}
				}
				incr memory_count
			}
		}
	}
	if {$memory_count == 0} {
		error "No memory nodes found!"
	}
	if {$memory_count > 1} {
		debug warning "Warning!: More than one memory found.  Note that most platforms don't support non-contiguous memory maps!"
	}
	return $tree
}

# Return 1 if the given interface of the given slave is connected to a bus.
proc bus_is_connected {slave face} {
	set busif_handle [xget_hw_busif_handle $slave $face]
	if {[llength $busif_handle] == 0} {
		error "Bus handle $face not found!"
	}
	set bus_name [xget_hw_value $busif_handle]

	set mhs_handle [xget_hw_parent_handle $slave]
	set bus_handle [xget_hw_ipinst_handle $mhs_handle $bus_name]

	return [llength $bus_handle]
}

# Populates a bus node with components connected to the given slave
# and adds it to the given tree
#
# tree         : Tree to populate
# slave_handle : The slave to use as a starting point, this is
# typically the root processor or a previously traversed bus bridge.
# intc_handle	: The interrupt controller associated with the
# processor. Slave will have an interrupts node relative to this
# controller.
# baseaddr     : The base address of the address range of this bus.
# face : The name of the port of the slave that is connected to the
# bus.
proc bus_bridge {slave intc_handle baseaddr face} {
	debug handles "+++++++++++ $slave ++++++++"
	set busif_handle [xget_hw_busif_handle $slave $face]
	if {[llength $busif_handle] == 0} {
		error "Bus handle $face not found!"
	}
	set bus_name [xget_hw_value $busif_handle]
	debug ip "IP connected to bus: $bus_name"
	debug handles "bus_handle: $busif_handle"

	set mhs_handle [xget_hw_parent_handle $slave]
	set bus_handle [xget_hw_ipinst_handle $mhs_handle $bus_name]

	# FIXME: remove compatible_list property and add simple-bus in  gen_compatible_property function
	set compatible_list {}
	if {[llength $bus_handle] == 0} {
		debug handles "Bus handle $face connected directly..."
		set slave_ifs [xget_hw_connected_busifs_handle $mhs_handle $bus_name "target"]
		set bus_type "xlnx,compound"
		set hw_ver ""
		set devicetype $bus_type
	} else {
		debug handles "Bus handle $face connected through a bus..."
		set bus_type [xget_hw_value $bus_handle]
		switch $bus_type {
			"axi_interconnect" {
				set devicetype "axi"
				set compatible_list [list "simple-bus"]
			}
			"plb_v34" -
			"plb_v46" {
				set devicetype "plb"
				set compatible_list [list "simple-bus"]
			}
			"opb_v20" {
				set devicetype "opb"
				set compatible_list [list "simple-bus"]
			}
			"dcr_v29" {
				set devicetype "dcr"
				set compatible_list [list "simple-bus"]
			}
			default {
				set devicetype $bus_type
			}
		}
		set hw_ver [xget_hw_parameter_value $bus_handle "HW_VER"]

		set master_ifs [xget_hw_connected_busifs_handle $mhs_handle $bus_name "master"]
		foreach if $master_ifs {
			set ip_handle [xget_hw_parent_handle $if]
			debug ip "-master [xget_hw_name $if] [xget_hw_value $if] [xget_hw_name $ip_handle]"
			debug handles "  handle: $ip_handle"

			# Note that bus masters do not need to be traversed, so we don't
			# add them to the list of ip.
		}
		set slave_ifs [xget_hw_connected_busifs_handle $mhs_handle $bus_name "slave"]
		if {[string match $devicetype "axi"]} {
			global axi_ifs
			set slave_ifs [concat $slave_ifs $axi_ifs]
		}
	}

	set bus_ip_handles {}
	# Compose peripherals & cleaning

	foreach if $slave_ifs {
		set ip_handle [xget_hw_parent_handle $if]
		debug ip "-slave [xget_hw_name $if] [xget_hw_value $if] [xget_hw_name $ip_handle]"
		debug handles "  handle: $ip_handle"

		# If its not already in the list, and its not the bridge, then
		# append it.
		if {$ip_handle != $slave} {
			if {[lsearch $bus_ip_handles $ip_handle] == -1} {
				lappend bus_ip_handles $ip_handle
			}
		}
	}
	# A list of all the IP that have been generated already.
	variable periphery_array

	# Start generating the node for the bus.
	set bus_node {}

	# Populate with all the slaves.
	foreach ip $bus_ip_handles {
		# If we haven't already generated this ip
		if {[lsearch $periphery_array $ip] == -1} {
			set bus_node [gener_slave $bus_node $ip $intc_handle]
			lappend periphery_array $ip
		}
	}

	# I have to generate led description on the same level as gpio node is
	# we are using designs with one plb - that's why is ok to have it here
	set led [led_gpio]
	if { "$led" != "" } {
		lappend bus_node $led
	}

	lappend bus_node [list \#size-cells int 1]
	lappend bus_node [list \#address-cells int 1]
	lappend bus_node [gen_compatible_property $bus_name $bus_type $hw_ver $compatible_list]

	return [list [format_ip_name $devicetype $baseaddr $bus_name] tree $bus_node]
}

# Return the clock frequency attribute of the port of the given ip core.
proc get_clock_frequency {ip_handle portname} {
	set clk ""
	set clkhandle [xget_hw_port_handle $ip_handle $portname]
	if {[string compare -nocase $clkhandle ""] != 0} {
		set clk [xget_hw_subproperty_value $clkhandle "CLK_FREQ_HZ"]
	}
	return $clk
}

# Return a sorted list of all the port names that we think are
# interrupts (i.e. those tagged in the mpd with SIGIS=INTERRUPT)
proc interrupt_list {ip_handle} {
	set port_handles [xget_hw_port_handle $ip_handle "*"]
	set interrupt_ports {}
	foreach port $port_handles {
		set name [xget_value $port "NAME"]
		set sigis [xget_hw_subproperty_value $port "SIGIS"]
		if {[string match $sigis "INTERRUPT"]} {
			lappend interrupt_ports $name
		}
	}
	return [lsort $interrupt_ports]
}

# Return a list of translation ranges for bridges which support
# multiple ranges with identity translation.
# ip_handle: handle to the bridge
# num_ranges_name: name of the bridge parameter which gives the number
# of active ranges.
# range_base_name_template: parameter name for the base address of
# each range, with a %d in place of the range number.
# range_high_name_template: parameter name for the high address of
# each range, with a %d in place of the range number.
proc default_ranges {ip_handle num_ranges_name range_base_name_template range_high_name_template} {
	set count [scan_int_parameter_value $ip_handle $num_ranges_name]
	if { [llength $count] == 0 } {
		set count 1
	}
	set ranges_list {}
	for {set x 0} {$x < $count} {incr x} {
		set baseaddr [scan_int_parameter_value $ip_handle [format $range_base_name_template $x]]
		set highaddr [scan_int_parameter_value $ip_handle [format $range_high_name_template $x]]
		lappend ranges_list [list $baseaddr $highaddr $baseaddr]
	}
	return $ranges_list
}

# Return a list of all the parameter names for the given ip that
# should be reported in the device tree for generic IP. This list
# includes all the parameter names, except those that are handled
# specially, such as the instance name, baseaddr, etc.
proc default_parameters {ip_handle} {
	set par_handles [xget_hw_parameter_handle $ip_handle "*"]
	set params {}
	foreach par $par_handles {
		set par_name [xget_hw_name $par]
		# Ignore some parameters that are always handled specially
		switch -glob $par_name {
			"INSTANCE" -
			"*BASEADDR" -
			"*HIGHADDR" -
			"C_SPLB*" -
			"C_OPB*" -
			"C_DPLB*" -
			"C_IPLB*" -
			"C_PLB*" -
			"C_M_AXI*" -
			"C_S_AXI_ADDR_WIDTH" -
			"C_S_AXI_DATA_WIDTH" -
			"C_S_AXI_ACLK_FREQ_HZ" -
			"C_S_AXI_LITE*" -
			"C_S_AXI_PROTOCOL" -
			"C_INTERCONNECT_?_AXI*" -
			"C_S_AXI_ACLK_PERIOD_PS" -
			"C_M*_AXIS*" -
			"C_S*_AXIS*" -
			"C_PRH*" -
			"HW_VER" {}
			default { lappend params $par_name }
		}
	}
	return $params
}

proc parameter_exists {ip_handle name} {
	set param_handle [xget_hw_parameter_handle $ip_handle $name]
	if {$param_handle == ""} {
		return 0
	}
	return 1
}

proc scan_int_parameter_value {ip_handle name} {
	set param_handle [xget_hw_parameter_handle $ip_handle $name]
	if {$param_handle == ""} {
		error "Can't find parameter $name in [xget_hw_name $ip_handle]"
		return 0
	}
	set value [xget_hw_value $param_handle]
	# tcl 8.4 doesn't handle binary literals..
	if {[string match 0b* $value]} {
		# Chop off the 0b
		set tail [string range $value 2 [expr [string length $value]-1]]
		# Pad to 32 bits, because binary scan ignores incomplete words
		set list [split $tail ""]
		for {} {[llength $list] < 32} {} {
			set list [linsert $list 0 0]
		}
		set tail [join $list ""]
		# Convert the remainder back to decimal
		binary scan [binary format "B*" $tail] "I*" value
	}
	return [expr $value]
}

proc format_name {par_name} {
	set par_name [string tolower $par_name]
	set par_name [string map -nocase {"_" "-"} $par_name]
	return $par_name
}

proc format_xilinx_name {name} {
	return "xlnx,[format_name $name]"
}

proc format_param_name {name trimprefix} {
	if {[string match [string range $name 0 [expr [string length $trimprefix] - 1]] $trimprefix]} {
		set name [string range $name [string length $trimprefix] [string length $name]]
	}
	return [format_xilinx_name $name]
}

proc format_ip_name {devicetype baseaddr {label ""}} {
	set node_name [format_name [format "%s@%x" $devicetype $baseaddr]]
	if {[string match $label ""]} {
		return $node_name
	} else {
		return [format "%s: %s" $label $node_name]
	}
}

proc gen_macaddr {ip_tree} {
	variable mac_count

	set seed4 [clock seconds]
	set seed5 [clock clicks]
	set mac_rand_b4 [expr $seed4 % 256]
	set mac_rand_b5 [expr $seed5 % 256]
	set ip_tree [tree_append $ip_tree [list "local-mac-address" bytesequence [list 0x00 0x0a 0x35 $mac_rand_b4 $mac_rand_b5 $mac_count]]]
	incr mac_count

	return $ip_tree
}

proc gen_phytree {slave intc} {
	variable phy_count

	set phy_tree [phy_mdio $slave $intc]
	if { "$phy_tree" != "" } {
		return $phy_tree
	}

	# TODO: We should remove this code
	debug warning "WARNING: Use default marvell,88e1111 for phy$phy_count. Can't generate correct."
	set phy_name [format_ip_name phy 7 "phy$phy_count"]
	set phy_tree [list $phy_name tree {}]
	set phy_tree [tree_append $phy_tree [list "reg" int 7]]
	set phy_tree [tree_append $phy_tree [list "device_type" string "ethernet-phy"]]
	set phy_tree [tree_append $phy_tree [list "compatible" string "marvell,88e1111"]]

	incr phy_count
	return $phy_tree
}

proc gen_mdiotree {slave intc} {
	set mdio_tree [list "mdio" tree {}]
	set mdio_tree [tree_append $mdio_tree [list \#size-cells int 0]]
	set mdio_tree [tree_append $mdio_tree [list \#address-cells int 1]]
	return [tree_append $mdio_tree [gen_phytree $slave $intc]]
}

# TODO: remove next two lines which is a temporary HACK for CR 532315
set num_intr_inputs -1

proc gen_params {node_list handle params {trimprefix "C_"} } {
	foreach par_name $params {
		if {[catch {
			set par_value [scan_int_parameter_value $handle $par_name]
			# TODO: remove next if elseif block which is a temporary HACK for CR 532315
			if {[string match C_NUM_INTR_INPUTS $par_name]} {
				set num_intr_inputs $par_value
			} elseif {[string match C_KIND_OF_INTR $par_name]} {
				# Pad to 32 bits - num_intr_inputs
				if {$num_intr_inputs != -1} {
					set count 0
					set mask 0
					set par_mask 0
					while {$count < $num_intr_inputs} {
						set mask [expr {1<<$count}]
						set new_mask [expr {$mask | $par_mask}]
						set par_mask $new_mask
						set new_count [expr {$count + 1}]
						set count $new_count
					}
					set par_value_32 $par_value
					set par_value [expr {$par_value_32 & $par_mask}]
				} else {
					debug warning "Warning: num-intr-inputs not set yet, kind-of-intr will be set to zero"
					set par_value 0
				}
					
			}
			lappend node_list [list [format_param_name $par_name $trimprefix] hexint $par_value]
		} {err}]} {
			set par_handle [xget_hw_parameter_handle $handle $par_name]
			if {$par_handle == ""} {
				debug warning "Warning: Unknown parameter name $par_name"
			} else {
				set par_value [xget_hw_value $par_handle]
			}
			lappend node_list [list [format_param_name $par_name $trimprefix] string $par_value]
		}
	}
	return $node_list
}

proc gen_compatible_property {nodename type hw_ver {other_compatibles {}} } {
	array set compatible_list [ list \
		{opb_intc} {xps_intc_1.00.a} \
		{opb_timer} {xps-timer-1.00.a} \
		{xps_timer} {xps-timer-1.00.a} \
		{axi_timer} {xps-timer-1.00.a} \
		{plb_v46} {plb_v46_1.00.a} \
		{plbv46_pci} {plbv46_pci_1.03.a} \
		{xps_bram_if_cntlr} {xps_bram_if_cntlr_1.00.a} \
		{axi_bram_ctrl} {xps_bram_if_cntlr_1.00.a} \
		{xps_ethernetlite} {xps_ethernetlite_1.00.a} \
		{axi_ethernetlite} {xps_ethernetlite_1.00.a} \
		{xps_gpio} {xps_gpio_1.00.a} \
		{axi_gpio} {xps_gpio_1.00.a} \
		{xps_hwicap} {xps_hwicap_1.00.a} \
		{xps_tft} {xps-tft-1.00.a} \
		{xps_iic} {xps_iic_2.00.a} \
		{axi_iic} {xps_iic_2.00.a} \
		{xps_intc} {xps_intc_1.00.a} \
		{axi_intc} {xps_intc_1.00.a} \
		{xps_ll_temac} {xps_ll_temac_1.01.b xps_ll_temac_1.00.a} \
		{axi_ethernet} {axi-ethernet-1.00.a} \
		{axi_dma} {axi-dma-1.00.a} \
		{xps_ps2} {xps_ps2_1.00.a} \
		{xps_spi_2} {xps_spi_2.00.a} \
		{axi_spi} {xps_spi_2.00.a} \
		{xps_uart16550_2} {xps_uart16550_2.00.a} \
		{axi_uart16550} {xps_uart16550_2.00.a} \
		{xps_uartlite} {xps_uartlite_1.00.a} \
		{axi_uartlite} {xps_uartlite_1.00.a} \
		{xps_can} {xps_can_1.00.a} \
		{xps_sysace} {xps_sysace_1.00.a} \
		{axi_sysace} {xps_sysace_1.00.a} \
		{xps_usb_host} {xps_usb_host_1.00.a} \
	]

	if {$hw_ver != ""} {
		set namewithver [format "%s_%s" $type $hw_ver]
		set clist [list [format_xilinx_name "$namewithver"]]
		regexp {([^\.]*)} $hw_ver hw_ver_wildcard
		set namewithwildcard [format "%s_%s" $type $hw_ver_wildcard]
		if { [info exists compatible_list($namewithver)] } {              # Check exact match
			set add_clist [list [format_xilinx_name "$compatible_list($namewithver)"]]
			set clist [concat $clist $add_clist]
		} elseif { [info exists compatible_list($namewithwildcard)] } {   # Check major wildcard match
			set add_clist [list [format_xilinx_name "$compatible_list($namewithwildcard)"]]
			set clist [concat $clist $add_clist]
		} elseif { [info exists compatible_list($type)] } {               # Check type wildcard match
			# Extended compatible property - for example ll_temac
			foreach single "$compatible_list($type)" {
				set add_clist [list [format_xilinx_name "$single"]]
				if { ![string match $clist $add_clist] } {
					set clist [concat $clist $add_clist]
				}
			}
		}
	} else {
		set clist [list [format_xilinx_name "$type"]]
	}
	set clist [concat $clist $other_compatibles]
	return [list "compatible" stringtuple $clist]
}

proc validate_ranges_property {slave parent_baseaddr parent_highaddr child_baseaddr} {
	set nodename [xget_hw_name $slave]
	if { ![llength $parent_baseaddr] || ![llength $parent_highaddr] } {
		error "Bad address range $nodename"
	}
	if {[string match $parent_highaddr "0x00000000"]} {
		error "Bad highaddr for $nodename"
	}
	set size [expr $parent_highaddr - $parent_baseaddr + 1]
	if { $size < 0 } {
		error "Bad highaddr for $nodename"
	}
	return $size
}

proc gen_ranges_property {slave parent_baseaddr parent_highaddr child_baseaddr} {
	set size [validate_ranges_property $slave $parent_baseaddr $parent_highaddr $child_baseaddr]
	return [list "ranges" hexinttuple [list $child_baseaddr $parent_baseaddr $size]]
}

proc gen_ranges_property_list {slave rangelist} {
	set ranges {}
	foreach range $rangelist {
		set parent_baseaddr [lindex $range 0]
		set parent_highaddr [lindex $range 1]
		set child_baseaddr [lindex $range 2]
		set size [validate_ranges_property $slave $parent_baseaddr $parent_highaddr $child_baseaddr]
		lappend ranges $child_baseaddr $parent_baseaddr $size
	}
	return [list "ranges" hexinttuple $ranges]
}

proc gen_interrupt_property_algo {tree intc interrupt_list} {
	set intc_name [xget_hw_name $intc]
	if {[llength $interrupt_list] != 0} {
		set tree [tree_append $tree [list "interrupts" inttuple $interrupt_list]]
		set tree [tree_append $tree [list "interrupt-parent" labelref $intc_name]]
	}
	return $tree
}

proc gen_interrupt_property {tree slave intc interrupt_port_list} {
	set pocet [scan_int_parameter_value $intc "C_NUM_INTR_INPUTS"]
	set pocet [expr $pocet - 1]
	set interrupt_list {}
	foreach in $interrupt_port_list {
		set irq [get_intr $slave $intc $pocet $in]

		if {![string match $irq "-1"]} {
			set irq_type [get_intr_type $slave $in]
			lappend interrupt_list $irq $irq_type
		}
	}
	return [gen_interrupt_property_algo $tree $intc $interrupt_list]
}

proc gen_interrupt_property_mhs {tree mhs intc interrupt_connector_list} {
	set pocet [scan_int_parameter_value $intc "C_NUM_INTR_INPUTS"]
	set pocet [expr $pocet - 1]
	set interrupt_list {}
	foreach in $interrupt_connector_list {
		set irq [get_intr_mhs $mhs $intc $pocet $in]

		if {![string match $irq "-1"]} {
			set irq_type [get_intr_type_mhs $mhs $in]
			lappend interrupt_list $irq $irq_type
		}
	}
	return [gen_interrupt_property_algo $tree $intc $interrupt_list]
}

proc gen_reg_property {nodename baseaddr highaddr {name "reg"}} {
	if { ![llength $baseaddr] || ![llength $highaddr] } {
		error "Bad address range $nodename"
	}
	if {[string match $highaddr "0x00000000"]} {
		error "No high address for $nodename"
	}
	# Detect undefined baseaddr for MPMC CTRL
	if {[string match "0x[format %x $baseaddr]" "0xffffffff"]} {
		error "No base address for $nodename"
	}
	set size [expr $highaddr - $baseaddr + 1]
	if { [format %x $size] < 0 } {
		error "Bad highaddr for $nodename"
	}
	return [list $name hexinttuple [list $baseaddr $size]]
}

proc reg_property_append {old new} {
	if {[lindex $old 0] != "reg"} {
		error {"reg_property_append called on $old, which is not a reg property."}
	}
	set name [lindex $old 0]
	set value [lindex $old 2]
	lappend value [lindex $new 2]
	return [list $name hexinttuple [join $value]]
}

proc write_value {file indent type value} {
	if {[catch {
		if {$type == "int"} {
			puts -nonewline $file "= <[format %d $value]>"
		} elseif {$type == "hexint"} {
			puts -nonewline $file "= <0x[format %x $value]>"
		} elseif {$type == "empty"} {
		} elseif {$type == "inttuple"} {
			puts -nonewline $file "= < "
			foreach element $value {
				puts -nonewline $file "[format %d $element] "
			}
			puts -nonewline $file ">"
		} elseif {$type == "hexinttuple"} {
			puts -nonewline $file "= < "
			foreach element $value {
				puts -nonewline $file "0x[format %x $element] "
			}
			puts -nonewline $file ">"
		} elseif {$type == "bytesequence"} {
			puts -nonewline $file "= \[ "
			foreach element $value {
				if {[expr $element > 255]} {
					error {"Value $element is not a byte!"}
				}
				puts -nonewline $file "[format %02x $element] "
			}
			puts -nonewline $file "\]"
		} elseif {$type == "labelref"} {
			puts -nonewline $file "= <&$value>"
		} elseif {$type == "labelref-ext"} {
			puts -nonewline $file "= < &"
			foreach element $value {
				puts -nonewline $file "$element "
			}
			puts -nonewline $file ">"
		} elseif {$type == "aliasref"} {
			puts -nonewline $file "= &$value"
		} elseif {$type == "string"} {
			puts -nonewline $file "= \"$value\""
		} elseif {$type == "stringtuple"} {
			puts -nonewline $file "= "
			set first true
			foreach element $value {
				if {$first != true} { puts -nonewline $file ", " }
				puts -nonewline $file "\"$element\""
				set first false
			}
		} elseif {$type == "tree"} {
			puts $file "{"
			write_tree $indent $file $value
			puts -nonewline $file "} "
		} else {
			puts "unknown type $type"
		}
	} {error}]} {
		puts $error
		puts -nonewline $file "= \"$value\""
	}
	puts $file ";"
}

# tree: a tree triple
# child_node: a tree triple
# returns: tree with child_node appended to the list of child nodes
proc tree_append {tree child_node} {
	if {[lindex $tree 1] != "tree"} {
		error {"tree_append called on $tree, which is not a tree."}
	}
	set name [lindex $tree 0]
	set node [lindex $tree 2]
	lappend node $child_node
	return [list $name tree $node]
}

proc write_nodes {indent file tree} {
	set tree [lsort -index 0 $tree]
	foreach node $tree {
		if { [llength $node] == 3} {
			set name [lindex $node 0]
			set type [lindex $node 1]
			set value [lindex $node 2]
			puts -nonewline $file "[tt [expr $indent + 1]]$name "
			write_value $file [expr $indent + 1] $type $value
		} elseif { [string match [llength $node] "4"] && [string match [lindex $node 1] "aliasref"] } {
			set name [lindex $node 0]
			set type [lindex $node 1]
			set value [lindex $node 2]
			puts -nonewline $file "[tt [expr $indent + 1]]$name "
			write_value $file [expr $indent + 1] $type $value
		} else {
			puts "Error_bad_tree_node length = [llength $node], $node"
		}
	}
}

proc write_tree {indent file tree} {
	set trees {}
	set nontrees {}
	foreach node $tree {
		if { [string match [lindex $node 1] "tree"]} {
			lappend trees $node
		} else {
			lappend nontrees $node
		}
	}
	write_nodes $indent $file $nontrees
	write_nodes $indent $file $trees

	puts -nonewline $file "[tt $indent]"
}

proc get_pathname_for_label {tree label {path /}} {
	foreach node $tree {
		set fullname [lindex $node 0]
		set type [lindex $node 1]
		set value [lindex $node 2]
		set nodelabel [string trim [lindex [split $fullname ":"] 0]]
		set nodename [string trim [lindex [split $fullname ":"] 1]]
		if {[string equal $label $nodelabel]} {
			return $path$nodename
		}
		if {$type == "tree"} {
			set p [get_pathname_for_label $value $label "$path$nodename/"]
			if {$p != ""} {return $p}
		}
	}
	return ""
}

proc dma_channel_config {xdma addr mode intc slave} {
	set modelow [string tolower $mode]
	set namestring "dma-channel"
	set channame [format_name [format "%s@%x" $namestring $addr]]

	set chan {}
	lappend chan [list compatible stringtuple [list [format "xlnx,%s-%s-channel" $xdma $modelow]]]
	set tmp [scan_int_parameter_value $slave [format "C_INCLUDE_%s_DRE" $mode]]
	lappend chan [list "xlnx,include-dre" hexint $tmp]

	set tmp [xget_hw_parameter_handle $slave [format "C_%s_AXIS_%s_TDATA_WIDTH" [string index $mode 0] $mode]]
	if {$tmp != ""} {
		set tmp [scan_int_parameter_value $slave [format "C_%s_AXIS_%s_TDATA_WIDTH" [string index $mode 0] $mode]]
		lappend chan [list "xlnx,datawidth" hexint $tmp]
	}

	set tmp [xget_hw_parameter_handle $slave [format "C_%s_AXIS_%s_DATA_WIDTH" [string index $mode 0] $mode]]
	if {$tmp != ""} {
		set tmp [scan_int_parameter_value $slave [format "C_%s_AXIS_%s_DATA_WIDTH" [string index $mode 0] $mode]]
		lappend chan [list "xlnx,datawidth" hexint $mode]
	}

	if { [string compare -nocase $xdma "axi-dma"] != 0} {
		set tmp [scan_int_parameter_value $slave [format "C_%s_GENLOCK_MODE" $mode]]
		lappend chan [list "xlnx,genlock-mode" hexint $tmp]
	}

	set chantree [list $channame tree $chan]
	set chantree [gen_interrupt_property $chantree $slave $intc [list [format "%s_introut" $modelow]]]

	return $chantree
}
