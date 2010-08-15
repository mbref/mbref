#
#	File: ecos_v2_1_0.tcl
#	Owner: Michal Simek
#
#	Copyright C - 2008 All rights reserved.
#				Michal Simek <monstr@monstr.eu>
#
#	No part of this program may be reproduced or adapted in any form
#	or by any means, electronic or mechanical, without permission from
#	Michal Simek. This program is confidential and may not be disclosed,
#	decompiled or reverse engineered without permission in writing from
#	Michal Simek
#	===================================================================
#
#	Michal Simek - eCos generator
#	Project is hosted only at http://www.monstr.eu/
#

# Globals variable
set version "ecos_v1.00.a"
set debug_level 5
# list of handled peripherals
set periphery_array ""
set gpio_count 0
set uart16550_count 0
set uartlite_count 0

proc ecos_drc {os_handle} {
	puts "\#--------------------------------------"
	puts "\# eCos BSP DRC...!"
	puts "\#--------------------------------------"
}

proc post_ecos {lib_handle} {
}


proc generate {os_handle} {
	puts "\#--------------------------------------"
	puts "\# eCos BSP generate..."
	puts "\#--------------------------------------"

	set eCos {}
	set proc_handle [xget_libgen_proc_handle]
	set hwproc_handle [xget_handle $proc_handle "IPINST"]
	set proctype [xget_value $hwproc_handle "OPTION" "IPNAME"]
	switch $proctype {
		"microblaze" {
			debug 0 "Microblaze CPU"
			set intc [get_handle_to_intc $hwproc_handle "Interrupt"]
			set eCos [gen_microblaze $eCos $hwproc_handle ""]
			set bus_handle [xget_hw_busif_handle $hwproc_handle "DLMB"]
			if {[llength $bus_handle] != 0} {
				set eCos "$eCos [bus_bridge $hwproc_handle $intc 0 "DLMB"]"
			} else {
				error "Please specify LMB memory"
			}

			set busif_handle [xget_hw_busif_handle $hwproc_handle "DPLB"]
			set bus_name [xget_hw_value $busif_handle]
			debug 5 "$busif_handle, $bus_name"
			if {[llength $bus_name] != 0} {
				# Microblaze v7 has PLB.
				puts "7"
				set eCos "$eCos [bus_bridge $hwproc_handle $intc 0 "DPLB"]"
			} else {
				# Older microblazes have OPB.
				set eCos "$eCos [bus_bridge $hwproc_handle $intc 0 "DOPB"]"
			}
		}
		default {
			error "unsupported CPU"
		}
	}

	set name [xget_sw_parameter_value $os_handle "name"]
	if {[llength $name] == 0} {
		error "Please specify board name"
	}

#I would like to do this with list of args :-(
	regsub -all " " $name "_" filename
	regsub -all "/" $filename "_" filename
	regsub -all "=" $filename "_" filename
	regsub -all {\.} $filename "_" filename
	regsub -all {\,} $filename "_" filename
	regsub -all {\*} $filename "_" filename
	regsub -all {\-} $filename "_" filename

	set filename [string tolower $filename]
	set path "hal/microblaze/$filename/v2_0/cdl"

	exec bash -c "mkdir -p $path"
	set f [open "$path/hal_microblaze_$filename.cdl" w]
	headerm $f
	puts $f [cdl_package_platform 0 $name [proc_h 1 $eCos $name]]
	close $f


	set f [open "ecos.db" w]
	package $f $name
	close $f

	variable uart16550_count
	if { $uart16550_count == 0} {
		puts "eCos currently doesn't support others uart then uart16550"
	}

#standalone part must be after petalogix
	variable version
#--M-- standalone part
	if {[ catch {exec test -d src } "" ]} {
		puts "\#--------------------------------------"
		puts "\# Standalone BSP generate..."
		puts "\#--------------------------------------"
#you must use top_version - because
		create_standalone_namespace $version $os_handle
	} else {
		file copy "./src/" "./../$version/src/"
	}
}

proc package {f name} {
	regsub -all " " $name "_" namef
	regsub -all "/" $namef "_" namef
	regsub -all "=" $namef "_" namef
	regsub -all {\.} $namef "_" namef
	regsub -all {\,} $namef "_" namef
	regsub -all {\*} $namef "_" namef
	regsub -all {\-} $namef "_" namef

	set nameup [string toupper $namef];
	set namedown [string tolower $namef];
	variable version
	puts $f "### start CYGPKG_HAL_MICROBLAZE_$nameup"
	puts $f "###############################################################################"
	puts $f "# Generate by $version - Copyright (C) Michal Simek 2008 <monstr@monstr.eu>"
	puts $f "###############################################################################"
	puts $f "package CYGPKG_HAL_MICROBLAZE_$nameup \{"
	puts $f "\talias\t\{ \"$name\" hal_microblaze_$namedown microblaze_$namedown\_hal \}"
	puts $f "\tdirectory\thal/microblaze/$namedown"
	puts $f "\tscript\t\thal_microblaze_$namedown.cdl"
	puts $f "\thardware"
	puts $f "\tdescription \" This platform is create by $version\""
	puts $f "\}\n"
	puts $f "target $namedown \{"
	puts $f "\talias\t\{ \"$name\" $namedown \}"
	puts $f "\tpackages \{\tCYGPKG_HAL_MICROBLAZE"
	puts $f "\t\t\tCYGPKG_HAL_MICROBLAZE_MB4A"
	puts $f "\t\t\tCYGPKG_HAL_MICROBLAZE_GENERIC"
	puts $f "\t\t\tCYGPKG_HAL_MICROBLAZE_$nameup"
	puts $f "\t\t\tCYGPKG_IO_SERIAL_GENERIC_16X5X"
	puts $f "\t\t\tCYGPKG_IO_SERIAL_MICROBLAZE_UART16550"
	puts $f "\t\t\tCYGPKG_IO_ETH_DRIVERS"
	puts $f "\t\t\tCYGPKG_DEVS_ETH_MICROBLAZE_EMACLITE"
	puts $f "\t\}"
	puts $f "\tdescription \" This target is create by $version\""
	puts $f "\}"
	puts $f "### end CYGPKG_HAL_MICROBLAZE_$nameup"
}

proc cdl_package_platform {i name body} {
	set c [expr $i + 1]
	regsub -all " " $name "_" namef
	regsub -all "/" $namef "_" namef
	regsub -all "=" $namef "_" namef
	regsub -all {\.} $namef "_" namef
	regsub -all {\,} $namef "_" namef
	regsub -all {\*} $namef "_" namef
	regsub -all {\-} $namef "_" namef

	set nameup [string toupper $namef];
	set s "[tt $i]cdl_package CYGPKG_HAL_MICROBLAZE_$nameup \{\n"
	set s "$s[tt $c]display\t\t\"$name\"\n"
	set s "$s[tt $c]parent\t\tCYGPKG_HAL_MICROBLAZE\n"
	set s "$s[tt $c]requires\tCYGPKG_HAL_MICROBLAZE_MB4A\n"
	set s "$s[tt $c]requires\tCYGPKG_HAL_MICROBLAZE_GENERIC\n"
	set s "$s[tt $c]define_header\thal_microblaze_platform.h\n"
	set s "$s[tt $c]include_dir\tcyg/hal\n"
	set s "$s[tt $c]description\t\"$name HAL package\"\n"
	set s "$s$body"
	set s "$s[tt $i]\}"
	return $s
}


proc proc_h {i eCos name} {
	set c [expr $i + 1]
	set s "[tt $i]define_proc \{\n"
	set s "$s[tt $c][header [incl pkgconf/hal_microblaze_generic.h]]\n"
	set s "$s[tt $c][header [def HAL_PLATFORM_BOARD "by $name"]]\n"
	variable version
	set s "$s[tt $c][header [def HAL_PLATFORM_EXTRA "by $version"]]\n"

	set cdl ""
	foreach node $eCos {
		switch [lindex $node 0] {
			"mem" {
				set s "$s[tt $c][comment [lindex $node 4]]\n"
				set s "$s[tt $c][header [def MON_[lindex $node 1]_BASE [lindex $node 2]]]\n"
				set s "$s[tt $c][header [def MON_[lindex $node 1]_HIGH [lindex $node 3]]]\n"
			}
			"ip" {
				set s "$s[tt $c][comment [lindex $node 5]]\n"
				set s "$s[tt $c][header [def MON_[lindex $node 1][lindex $node 2]_BASE [lindex $node 3]]]\n"
				if { [lindex $node 4] != ""} {
					set s "$s[tt $c][header [def MON_[lindex $node 1][lindex $node 2]_INTR [lindex $node 4]]]\n"
				}
				lappend cdl [list bool "[lindex $node 1][lindex $node 2]" "1" [lindex $node 5] ]
			}
			"time" {
				set s "$s[tt $c][comment [lindex $node 5]]\n"
				set s "$s[tt $c][header [def MON_[lindex $node 1][lindex $node 2]_BASE [lindex $node 3]]]\n"
				if { [lindex $node 4] != ""} {
					set s "$s[tt $c][header [def MON_[lindex $node 1][lindex $node 2]_INTR [lindex $node 4]]]\n"
				} else {
					error "Please connect [lindex $node 5] to interrupt controller"
				}
			}
			"intc" {
				set s "$s[tt $c][comment [lindex $node 3]]\n"
				set s "$s[tt $c][header [def MON_INTC_BASE [lindex $node 1]]]\n"
				set s "$s[tt $c][header [def MON_INTC_NUM_INTR [lindex $node 2]]]\n"
			}
			"emaclite" {
#			lappend ip [list emaclite "EMACLITE" "$base" "$tx" "$rx" "$intr" "$name" ]
				set s "$s[tt $c][comment [lindex $node 6]]\n"
				set s "$s[tt $c][header [def MON_[lindex $node 1]_BASE [lindex $node 2]]]\n"
				set s "$s[tt $c][header [def MON_[lindex $node 1]_TX_PING_PONG [lindex $node 3]]]\n"
				set s "$s[tt $c][header [def MON_[lindex $node 1]_RX_PING_PONG [lindex $node 4]]]\n"
				set s "$s[tt $c][header [def MON_[lindex $node 1]_INTR [lindex $node 5]]]\n"
				lappend cdl [list bool "[lindex $node 1]_0" "1" [lindex $node 6] ]
			}
			"clk" {
				set s "$s[tt $c][header [def MON_CPU_[lindex $node 1] [lindex $node 2]]]\n"
				lappend cdl [list data "[lindex $node 1]" "[expr [lindex $node 2] / 1000000 ]" "System CLK" ]
			}
			"cpu" {
# FIXME need to solve cflags
				set s "$s[tt $c][header [def MON_CPU_[lindex $node 1] [lindex $node 2]]]\n"
			}
			default {
				
			}
		}
	}
	set s "$s[tt $i]\}\n"


	foreach n $cdl {
		set s "$s[cdl_option $i $n]"
	}
	return $s
}

proc cdl_option {i name} {
	if { [lindex $name 0] == "bool"} {
		return [cdl_option_bool $i [lindex $name 1] [lindex $name 2] [lindex $name 3]]
	} else {
		return [cdl_option_data $i [lindex $name 1] [lindex $name 2] [lindex $name 3]]
	}
}

proc cdl_option_bool {i name val desc} {
	set nameup [string toupper $name];
	set c [expr $i + 1]
	set s "[tt $i]cdl_option MON_$nameup \{\n"
	set s "$s[tt $c]display\t\t\"$nameup IP core support\"\n"
	set s "$s[tt $c]flavor\t\tbool\n"
	set s "$s[tt $c]default_value\t$val\n"
	set s "$s[tt $c]description\t\"Enabling this option adds support to $desc.\"\n"
	set s "$s[tt $i]\}\n"
	return $s
}

# FIXME add possible value
proc cdl_option_data {i name val desc} {
	set nameup [string toupper $name];
	set c [expr $i + 1]
	set s "[tt $i]cdl_option MON_$nameup \{\n"
	set s "$s[tt $c]display\t\t\"$nameup IP core support\"\n"
	set s "$s[tt $c]flavor\t\tdata\n"
	set s "$s[tt $c]default_value\t$val\n"
	set s "$s[tt $c]description\t\"$desc.\"\n"
	set s "$s[tt $i]\}\n"
	return $s
}



proc header {name} {
	return "puts \$::cdl_header \"$name\""
}

proc comment {name} {
	return [header "/* $name */"]
}

proc incl {name} {
	return "#include <$name>"
}

# FIXME add test on numbers not for length
proc def {name val} {
	if {[llength $val] > 1} {
		return "#define $name\t\\\"$val\\\""
	}
	return "#define $name\t$val"
}


#retun number of tabulator
proc tt {number} {
	set tab ""
	for {set x 0} {$x < $number} {incr x} {
		set tab "$tab\t"
	}
	return $tab
}


proc bus_bridge {slave intc_handle baseaddr face} {
	set busif_handle [xget_hw_busif_handle $slave $face]
	if {[llength $busif_handle] == 0} {
		error "Bus handle $face not found!"
	}
	set bus_name [xget_hw_value $busif_handle]

	debug 3 "--$busif_handle, $bus_name"
	set mhs_handle [xget_hw_parent_handle $slave]
	set bus_handle [xget_hw_ipinst_handle $mhs_handle $bus_name]
	debug 3 "--$bus_handle, mhs_handle"
	set bus_type [xget_hw_value $bus_handle]
	switch $bus_type {
		"plb_v46" -
		"opb_v20" {
			debug 6 "opb or plb bus handling"
# I don't care about masters on bus
#			set master_ifs [xget_hw_connected_busifs_handle $mhs_handle $bus_name "master"]
			variable periphery_array
			set desc ""
			set slave_ips [xget_hw_connected_busifs_handle $mhs_handle $bus_name "slave"]
			foreach ip $slave_ips {
				set ip_handle [xget_hw_parent_handle $ip]

				# If we haven't already generated this ip
				if {[lsearch $periphery_array $ip] == -1} {
					set desc "$desc [gener_slave $ip_handle $intc_handle]"
					lappend periphery_array $ip
				} else {
					debug 3 "Is already add to list"
				}
			}
		}
		"lmb_v10" {
			debug 6 "lmb bus handling"
			set bram_mem [xget_hw_connected_busifs_handle $mhs_handle $bus_name "slave"]
			set ip_handle [xget_hw_parent_handle $bram_mem]
			set desc [gener_slave $ip_handle ""]
		}
		default {
			error "Unknown bus interface"

		}
	}
	return $desc
}

proc gener_slave {slave intc} {
	set name [xget_hw_name $slave]
	set type [xget_hw_value $slave]
	set ip ""
	switch -exact $type {
		"lmb_bram_if_cntlr" {
			set base [par_val $slave "C_BASEADDR"]
			set high [par_val $slave "C_HIGHADDR"]
			lappend ip [list mem "BRAM" "$base" "$high" "$name"]
			debug 6 "BRAM $base $high $name"

		}
		"mch_opb_ddr" {
			set base [par_val $slave "C_MEM0_BASEADDR"]
			set high [par_val $slave "C_MEM0_HIGHADDR"]
			lappend ip [list mem "MEMORY" "$base" "$high" "$name"]
			debug 6 "MEMORY $base $high $name"
		}
		"mpmc" {
			set base [par_val $slave "C_MPMC_BASEADDR"]
			set high [par_val $slave "C_MPMC_HIGHADDR"]
			lappend ip [list mem "MEMORY" "$base" "$high" "$name"]
			debug 1 "MEMORY $base $high $name"
		}
		"xps_uartlite" -
		"opb_uartlite" {
			variable uartlite_count
			set base [par_val $slave "C_BASEADDR"]
			set intr [get_intr $slave $intc "Interrupt"]
			if { $intr == -1 } {
				warning "Please connect $name to interrupt controller"
			}
			lappend ip [list ip "UARTLITE" "_$uartlite_count" "$base" "$intr" "$name"]
			set uartlite_count [expr $uartlite_count + 1]
		}
		"xps_uart16550" -
		"plb_uart16550" -
		"opb_uart16550" {
			variable uart16550_count
			set base [par_val $slave "C_BASEADDR"]
			set intr [get_intr $slave $intc "IP2INTC_Irpt"]
			if { $intr == -1 } {
				error "Please connect $name to interrupt controller"
			}
			lappend ip [list ip "UART16550" "_$uart16550_count" "$base" "$intr" "$name"]
			set uart16550_count [expr $uart16550_count + 1]
		}
		"opb_gpio" -
		"xps_gpio" {
			variable gpio_count
			set base [par_val $slave "C_BASEADDR"]
			lappend ip [list ip "GPIO" "_$gpio_count" "$base" "" "$name"]
			set gpio_count [expr $gpio_count + 1]
		}
		"opb_intc" -
		"xps_intc" {
			set base [par_val $slave "C_BASEADDR"]
			set num [par_val $slave "C_NUM_INTR_INPUTS"]
			lappend ip [list intc "$base" "$num" "$name"]
			debug 6 "INTC $base $num"
		}
		"xps_timer" -
		"opb_timer" {
			set intr [get_intr $slave $intc "Interrupt"]
			if { $intr == -1 } {
				error "Please connect $name to interrupt controller"
			}
			set base [par_val $slave "C_BASEADDR"]
			lappend ip [list time "TIMER" "" "$base" "$intr" "$name"]

		}
		"opb_ethernetlite" -
		"xps_ethernetlite" {
			set intr [get_intr $slave $intc "IP2INTC_Irpt"]
			if { $intr == -1 } {
				error "Please connect $name to interrupt controller"
			}
			set base [par_val $slave "C_BASEADDR"]
			set tx [par_val $slave "C_TX_PING_PONG"]
			set rx [par_val $slave "C_RX_PING_PONG"]
			debug 6 "EMACLITE $base $tx $rx interrupt $intr"
			lappend ip [list emaclite "EMACLITE" "$base" "$tx" "$rx" "$intr" "$name" ]
		}
		default {
			debug 5 "unsupported IP $slave $name"
			return ""
		}
	}
	return $ip

}


proc get_intr {per_handle intc port_name} {
	if {![string match "" $intc] && ![string match -nocase "none" $intc]} {
		set intc_signals [get_intc_signals $intc]
		set port_handle [xget_hw_port_handle $per_handle "$port_name"]
		set interrupt_signal [xget_value $port_handle "VALUE"]
		set index [lsearch $intc_signals $interrupt_signal]
		if {$index == -1} {
			return -1
		} else {
			# interrupt 0 is last in list.
			return [expr [llength $intc_signals] - $index ]
		}
	} else {
		return -1
	}
}

proc get_intc_signals {intc} {
	set signals [split [xget_hw_port_value $intc "intr"] "&"]
	set intc_signals {}
	foreach signal $signals {
		lappend intc_signals [string trim $signal]
	}
	return $intc_signals
}





proc gen_microblaze {tree hwproc_handle params} {
	set cpu {}

	set cpu_name [xget_hw_name $hwproc_handle]
	set cpu_type [xget_hw_value $hwproc_handle]
	set cpu_ver [xget_hw_parameter_value $hwproc_handle "HW_VER"]
	debug 6 "cpu name(type) = $cpu_name ($cpu_type) $cpu_ver"

# cache handling
	set icache_size [par_val $hwproc_handle "C_CACHE_BYTE_SIZE"]
	lappend cpu [ list cpu "ICACHE_SIZE" $icache_size]
	debug 6 "icache size = $icache_size"
	if { [llength $icache_size] != 0 } {
		set icache_base [par_val $hwproc_handle "C_ICACHE_BASEADDR"]
		lappend cpu [ list cpu "ICACHE_BASE" $icache_base]
		debug 6 "icache base = $icache_base"
		set icache_high [par_val $hwproc_handle "C_ICACHE_HIGHADDR"]
		lappend cpu [ list cpu "ICACHE_HIGH" $icache_high]
		debug 6 "icache high = $icache_high"
	}

	set dcache_size [par_val $hwproc_handle "C_DCACHE_BYTE_SIZE"]
	lappend cpu [ list cpu "DCACHE_SIZE" $dcache_size]
	debug 6 "dcache size = $dcache_size"
	if { [llength $dcache_size] != 0 } {
		set dcache_base [par_val $hwproc_handle "C_DCACHE_BASEADDR"]
		lappend cpu [ list cpu "DCACHE_BASE" $dcache_base]
		debug 6 "dcache base = $dcache_base"
		set dcache_high [par_val $hwproc_handle "C_DCACHE_HIGHADDR"]
		lappend cpu [ list cpu "DCACHE_HIGH" $dcache_high]
		debug 6 "dcache high = $dcache_high"
	}
# FIXME only for microblaze higher version
#	set icache_line_size [expr 4*[par_val $hwproc_handle "C_ICACHE_LINE_LEN"]]
#	debug 6 "icache line size = $icache_line_size"
#	set dcache_line_size [expr 4*[par_val $hwproc_handle "C_DCACHE_LINE_LEN"]]
#	debug 6 "dcache line size = $dcache_line_size"
	# Get the clock frequency from the processor


#	set clk [get_clock_frequency $hwproc_handle "CLK"]
#	debug 0 "Clock Frequency: $clk"

# FIXME based on MSS - but it is important for uart16550
	set proc_handle [xget_libgen_proc_handle]
	set sys_clock [xget_sw_parameter_value $proc_handle "CORE_CLOCK_FREQ_HZ"]
	if { [llength $sys_clock] != 0 } {
		lappend cpu [list clk "SYSTEM_CLK" $sys_clock]
	} else {
		set hwproc_handle [xget_handle $proc_handle "IPINST"]
		# Get the clock frequency from the processor
		set clkhandle [xget_hw_port_handle $hwproc_handle "CLK"]
		if {[string compare -nocase $clkhandle ""] != 0} {
			set sys_clock [xget_hw_subproperty_value $clkhandle "CLK_FREQ_HZ"]
			lappend cpu [list clk "SYSTEM_CLK" $sys_clock]
		} else {
			error "CLK not defined"
		}
	}

	foreach arg "MSR_INSTR BARREL DIV HW_MUL PCMP_INSTR FPU" {
		set val [par_val $hwproc_handle "C_USE_$arg"]
		lappend cpu [list cpu "$arg" "$val"]
		debug 6 "$arg $val"
	}

	return $cpu
}

# return parameter value
proc par_val {handle name} {
	set param_handle [xget_hw_parameter_handle $handle $name]
	if {$param_handle == ""} {
		error "Can't find parameter $name in [xget_hw_name $handle]"
		return 0
	}
	return [xget_hw_value $param_handle]
}

proc headerm {ufile} {
	variable version
	puts $ufile "\#"
	puts $ufile "\# (C) Copyright 2008 Michal Simek"
	puts $ufile "\#"
	puts $ufile "\# Michal SIMEK <monstr@monstr.eu>"
	puts $ufile "\#"
	puts $ufile "\# This file is generated by $version."
	puts $ufile "\# Project is hosted only at http://www.monstr.eu/"
	puts $ufile "\#"
	puts $ufile "\#"
	puts $ufile "\# Please report all bugs in this file to Michal SIMEK"
	puts $ufile "\# Version: [xget_swverandbld]"
	puts $ufile "\#"
	puts $ufile ""
}


# get handle to interrupt controller from CPU handle
proc get_handle_to_intc {hwproc_handle port_name} {
	#hangle to mhs file
	set mhs_handle [xget_hw_parent_handle $hwproc_handle]
	#get handle to interrupt port on Microblaze
	set intr_port [xget_value $hwproc_handle "PORT" $port_name]
	if { [llength $intr_port] == 0 } {
		error "CPU has not connection to Interrupt controller"
	}
	#get source port periphery handle - on interrupt controller
	set source_port [xget_hw_connected_ports_handle $mhs_handle $intr_port "source"]
	#get interrupt controller handle
	set intc [xget_hw_parent_handle $source_port]
	set name [xget_hw_name $intc]
	debug 5 "Interrupt controller found $name $intc"
	return $intc
}

# help function for debug purpose
# levels:
# 0 - important information
# 5 - debug information
proc debug {level string} {
	variable debug_level
	if { $level < $debug_level} {
		puts $string
	}
}

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
#	cd "./../$name"

	file mkdir "./src"
	file copy ${orig_mbsrcdir} $mbsrcdir
	file copy ${orig_ppcsrcdir} $ppcsrcdir
	file copy ${orig_profilesrcdir} $profilesrcdir
	puts "Calling standalone::generate"

	standalone_bsp::generate $os_handle
}
