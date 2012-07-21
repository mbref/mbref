#
# SDK software application generator for XL-Boot
# supporting Microblaze (and PPC ???)
#
# (C) Copyright 2010-2012
# Li-Pro.Net <www.li-pro.net>
# Stephan Linz <linz@li-pro.net>
#
# (C) Copyright 2010-2012 Xilinx, Inc.
# Borrowed in parts from SREC Bootloader
# ${XILINX_EDK}/sw/lib/sw_apps/bootloader
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

proc swapp_get_name {} {
    return "XL-Boot";
}

proc swapp_get_description {} {
    return "XL-Boot (Xilinx Locate Bootloader) is a simple bootloader for loading locate blob images, so named XLBLOB images, from non volatile memory. This program assumes that you have an XLBLOB image programmed into flash memory already. The program also assumes that the XLBLOB image is an application for this processor that does not overlap the bootloader and resides in separate physical memory in the hardware. Typically this bootloader application is initialized into BRAM so that it bootloads the XLBLOB image when the FPGA is powered up.

Don't forget to define XLB_LOCBLOB_OFFSET in your project setup to reflect the physical address where your XLBLOB image resides in non-volatile memory!";
}

proc check_tpos_os {} {
    set oslist [xget_sw_modules "type" "os"];

    if { [llength $oslist] != 1 } {
	return 0;
    }
    set os [lindex $oslist 0];

    if { $os != "tpos" } {
	error "This bootloader is supported only on the ThirdParty OS Board Support Package.";
    }
}

proc generate_stdout_config {fid} {
    set stdout [xget_sw_module_parameter "tpos" "STDOUT"];

    # if stdout is uartlite, we don't have to generate anything
    set stdout_type [xget_ip_attribute "type" $stdout];

    if { [regexp -nocase "uartlite" $stdout_type] || [string match -nocase "mdm" $stdout_type] } {
	return;
    } elseif { [regexp -nocase "uart16550" $stdout_type] } {
	# mention that we have a 16550
	puts $fid "#define STDOUT_IS_16550";

	# and note down its base address
	set prefix "XPAR_";
	set postfix "_BASEADDR";
	set stdout_baseaddr_macro $prefix$stdout$postfix;
	set stdout_baseaddr_macro [string toupper $stdout_baseaddr_macro];
	puts $fid "#define STDOUT_BASEADDR $stdout_baseaddr_macro";
    }
}

proc get_os {} {
    set oslist [xget_sw_modules "type" "os"];
    set os [lindex $oslist 0];

    if { $os == "" } {
	error "No Operating System specified in the Board Support Package.";
    }
    
    return $os;
}

proc get_stdout {} {
    set os [get_os];
    set stdout [xget_sw_module_parameter $os "STDOUT"];
    return $stdout;
}

proc check_stdout_hw {} {
    set uartlites [xget_ips "type" "uartlite"];
    if { [llength $uartlites] == 0 } {
	# we do not have an uartlite
	set uart16550s [xget_ips "type" "uart16550"];
	if { [llength $uart16550s] == 0 } {      
	    # Check for MDM-Uart peripheral. The MDM would be listed as a peripheral
	    # only if it has a UART interface. So no further check is required
	    set mdms [xget_ips "type" "mdm"]
	    if { [llength $mdms] == 0 } {
		error "This application requires a Uart IP in the hardware."
	    }
	}
    }
}

proc check_stdout_sw {} {
    set stdout [get_stdout];
    if { $stdout == "none" } {
	error "The STDOUT parameter is not set on the OS. The bootloader requires STDOUT to be set."
    }
}

proc get_mem_size { memlist } {
    return [lindex $memlist 4];
}

proc require_memory {memsize} {
    set imemlist [xget_memory_ranges "access_type" "I"];
    set idmemlist [xget_memory_ranges "access_type" "ID"];
    set dmemlist [xget_memory_ranges "access_type" "D"];

    set memlist [concat $imemlist $idmemlist $dmemlist];

    while { [llength $memlist] > 3 } {
	set mem [lrange $memlist 0 4];
	set memlist [lreplace $memlist 0 4];

	if { [get_mem_size $mem] >= $memsize } {
	    return 1;
	}
    }

    error "This application requires atleast $memsize bytes of memory.";
}

# be left swapp_is_supported for backward compatibility (11.x)
proc swapp_is_supported {} {
    # check for tpos OS
    check_tpos_os;

    # check for uart peripheral
    check_stdout_sw;

    # we require atleast 8KB memory
    require_memory "8192";
}

proc swapp_is_supported_hw {} {
    # bootloader is supported only for microblaze targets
    set proc_instance [xget_processor_name];
    set proc_type [xget_ip_attribute "type" $proc_instance];

    # TODO: expand for PPC, use:
    #    && ($proc_type != "ppc405")
    #    && ($proc_type != "ppc405_virtex4")
    #    && ($proc_type != "ppc440_virtex5")
    if { ($proc_type != "microblaze") } {
	error "This application is supported only for MicroBlaze processors";
    }

    # check for uart peripheral
    check_stdout_hw;

    # we require atleast 8KB memory
    require_memory "8192";
}

proc swapp_is_supported_sw {} {
    # check for tpos OS
    check_tpos_os;

    # check for stdout being set
    check_stdout_sw;
}

proc generate_cache_mask { fid } {
    set mask [format "0x%x" [xget_ppc_cache_mask]]
    puts $fid "#ifdef __PPC__"
    puts $fid "#define CACHEABLE_REGION_MASK $mask"
    puts $fid "#endif\n"
}

proc swapp_generate {} {
    # cleanup this file for writing
    set fid [open "platform_config.h" "w+"];
    puts $fid "#ifndef __PLATFORM_CONFIG_H_";
    puts $fid "#define __PLATFORM_CONFIG_H_\n";

    # if we have a uart16550 as stdout, then generate some config for that
    generate_stdout_config $fid;

    # for ppc, generate cache mask string
    generate_cache_mask $fid;

    puts $fid "#endif";
    close $fid;
}

proc get_mem_name { memlist } {
    return [lindex $memlist 0];
}

proc get_mem_type { memlist } {
    return [lindex $memlist 1];
}

proc get_mem_ip { memlist } {
    return [lindex $memlist 2];
}

proc get_mem_base { memlist } {
    return [format "%08x" [lindex $memlist 3]];
}

proc get_mem_size { memlist } {
    return [lindex $memlist 4];
}

proc extract_bram_memories { memlist } {
    set bram_mems [];
    set l [llength $memlist];
    while { [llength $memlist] > 3 } {
	set mem [lrange $memlist 0 4];
	set memlist [lreplace $memlist 0 4];

	if { [get_mem_type $mem] == "BRAM" } {
	    set bram_mems [concat $bram_mems $mem];
	}
    }

    return $bram_mems;
}

proc get_program_code_memory {} {
    set imemlist [xget_memory_ranges "access_type" "I"];
    set idmemlist [xget_memory_ranges "access_type" "ID"];

    set memlist [concat $imemlist $idmemlist];
    set codemem [extract_bram_memories $memlist];
    return $codemem;
}

proc get_program_data_memory {} {
    set dmemlist [xget_memory_ranges "access_type" "D"];
    set idmemlist [xget_memory_ranges "access_type" "ID"];

    set memlist [concat $dmemlist $idmemlist];
    set datamem [extract_bram_memories $memlist];
    return $datamem;
}

proc swapp_get_linker_constraints {} {
    set code_memory [get_mem_name [get_program_code_memory]];
    set data_memory [get_mem_name [get_program_data_memory]];

    # set code & data memory to point to bram
    # no need for vectors section (affects PPC linker scripts only)
    # no need for heap
    return "code_memory $code_memory data_memory $data_memory vector_section no stack 512 heap 0";
}
