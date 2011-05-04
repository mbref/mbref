## -- ************************************************************************
## -- ** DISCLAIMER OF LIABILITY                                            **
## -- **                                                                    **
## -- ** This file contains proprietary and confidential information of     **
## -- ** Xilinx, Inc. ("Xilinx"), that is distributed under a license       **
## -- ** from Xilinx, and may be used, copied and/or disclosed only         **
## -- ** pursuant to the terms of a valid license agreement with Xilinx.    **
## -- **                                                                    **
## -- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION              **
## -- ** ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER         **
## -- ** EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT                **
## -- ** LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,          **
## -- ** MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx      **
## -- ** does not warrant that functions included in the Materials will     **
## -- ** meet the requirements of Licensee, or that the operation of the    **
## -- ** Materials will be uninterrupted or error-free, or that defects     **
## -- ** in the Materials will be corrected. Furthermore, Xilinx does       **
## -- ** not warrant or make any representations regarding use, or the      **
## -- ** results of the use, of the Materials in terms of correctness,      **
## -- ** accuracy, reliability or otherwise.                                **
## -- **                                                                    **
## -- ** Xilinx products are not designed or intended to be fail-safe,      **
## -- ** or for use in any application requiring fail-safe performance,     **
## -- ** such as life-support or safety devices or systems, Class III       **
## -- ** medical devices, nuclear facilities, applications related to       **
## -- ** the deployment of airbags, or any other applications that could    **
## -- ** lead to death, personal injury or severe property or               **
## -- ** environmental damage (individually and collectively, "critical     **
## -- ** applications"). Customer assumes the sole risk and liability       **
## -- ** of any use of Xilinx products in critical applications,            **
## -- ** subject only to applicable laws and regulations governing          **
## -- ** limitations on product liability.                                  **
## -- **                                                                    **
## -- ** Copyright 2005, 2006, 2008, 2009 Xilinx, Inc.                      **
## -- ** All rights reserved.                                               **
## -- **                                                                    **
## -- ** This disclaimer and copyright notice must be retained as part      **
## -- ** of this file at all times.                                         **
## -- ************************************************************************
## s2imac_epc_v2_1_0.tcl
##############################################################################

#***--------------------------------***------------------------------------***
#
#                            IPLEVEL_DRC_PROC
#
#***--------------------------------***------------------------------------***

proc check_iplevel_settings {mhsinst} {

    check_max_awidth $mhsinst
    check_max_dwidth $mhsinst
    check_adwidth    $mhsinst
    check_wrn_width  $mhsinst
    check_rdn_width  $mhsinst
    check_rdy_tout   $mhsinst

}


#
# C_PRH_MAX_AWIDTH = max(C_PRHx_AWIDTH), x = 0 to C_NUM_PERIPHERALS - 1
#
proc check_max_awidth {mhsinst} {

    set max_awidth [xget_hw_parameter_value $mhsinst "C_PRH_MAX_AWIDTH"]
    set num_peri   [xget_hw_parameter_value $mhsinst "C_NUM_PERIPHERALS"]
    set max "0"

    for {set i 0} {$i < $num_peri} {incr i} {

        set peri_param  [concat C_PRH${i}_AWIDTH]
        set peri_value  [xget_hw_parameter_value $mhsinst $peri_param ]

        if {$peri_value > $max} {

            set max $peri_value
        }
    }

    if {$max_awidth != $max} {

        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        error "\nInvalid $instname parameter:\nC_PRH_MAX_AWIDTH must be the maximum value among width of peripheral address bus.\n" "" "mdt_error"

    }

}

#
# C_PRH_MAX_DWIDTH = Max (C_PRHx_DWIDTH), x = 0 to C_NUM_PERIPHERALS - 1
#
proc check_max_dwidth {mhsinst} {

    set max_dwidth [xget_hw_parameter_value $mhsinst "C_PRH_MAX_DWIDTH"]
    set num_peri   [xget_hw_parameter_value $mhsinst "C_NUM_PERIPHERALS"]
    set max "0"

    for {set i 0} {$i < $num_peri} {incr i} {

        set peri_param  [concat C_PRH${i}_DWIDTH]
        set peri_value  [xget_hw_parameter_value $mhsinst $peri_param ]

        if {$peri_value > $max} {

            set max $peri_value
        }
    }

    if {$max_dwidth != $max} {

        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        error "\nInvalid $instname parameter:\nC_PRH_MAX_DWIDTH must be the maximum value among width of peripheral data bus\n" "" "mdt_error"

    }


}

#
# C_PRH_MAX_ADWIDTH >= C_PRH_MAX_DWIDTH
#
proc check_adwidth {mhsinst} {

    set max_adwidth [xget_hw_parameter_value $mhsinst "C_PRH_MAX_ADWIDTH"]
    set max_dwidth  [xget_hw_parameter_value $mhsinst "C_PRH_MAX_DWIDTH"]

    if {$max_adwidth < $max_dwidth} {

        set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
        error "\nInvalid $instname parameter:\nC_PRH_MAX_ADWIDTH must be greater than or equal to C_PRH_MAX_DWIDTH\n" "" "mdt_error"

    }
}

#
# if C_PRHx_SYNC = 0 then
# C_PRHx_WRN_WIDTH < C_PRHx_WR_CYCLE,    x = 0 to C_NUM_PERIPHERALS - 1
#
proc check_wrn_width {mhsinst} {

    set num_peri   [xget_hw_parameter_value $mhsinst "C_NUM_PERIPHERALS"]

    for {set i 0} {$i < $num_peri} {incr i} {

        set wrn_width_param  [concat C_PRH${i}_WRN_WIDTH]
        set wr_cycle_param   [concat C_PRH${i}_WR_CYCLE]
        set sync_param       [concat C_PRH${i}_SYNC]
        set wrn_width_value  [xget_hw_parameter_value $mhsinst $wrn_width_param]
        set wr_cycle_value   [xget_hw_parameter_value $mhsinst $wr_cycle_param]
        set sync_value       [xget_hw_parameter_value $mhsinst $sync_param]

        if {$sync_value == 0 && $wrn_width_value >= $wr_cycle_value} {

            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            error "\nInvalid $instname parameter:\n$wrn_width_param must be less than $wr_cycle_param\n" "" "mdt_error"

        }
    }
}

#
# if C_PRHx_SYNC = 0 then
# C_PRHx_RDN_WIDTH < C_PRHx_RD_CYCLE,    x = 0 to C_NUM_PERIPHERALS - 1
#
proc check_rdn_width {mhsinst} {

    set num_peri   [xget_hw_parameter_value $mhsinst "C_NUM_PERIPHERALS"]

    for {set i 0} {$i < $num_peri} {incr i} {

        set rdn_width_param  [concat C_PRH${i}_RDN_WIDTH]
        set rd_cycle_param   [concat C_PRH${i}_RD_CYCLE]
        set sync_param       [concat C_PRH${i}_SYNC]
        set rdn_width_value  [xget_hw_parameter_value $mhsinst $rdn_width_param]
        set rd_cycle_value   [xget_hw_parameter_value $mhsinst $rd_cycle_param]
        set sync_value       [xget_hw_parameter_value $mhsinst $sync_param]

        if {$sync_value == 0 && $rdn_width_value >= $rd_cycle_value} {

            set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
            error "\nInvalid $instname parameter:\n$rdn_width_param must be less than $rd_cycle_param\n" "" "mdt_error"

        }
    }
}

#
# if C_PRHx_SYNC = 0 then
# C_PRHx_RDY_TOUT < min(C_PRHx_WRN_WIDTH, C_PRHx_RDN_WIDTH, C_PRHx_RDY_WIDTH), 
#               x = 0 to C_NUM_PERIPHERALS - 1
#
proc check_rdy_tout {mhsinst} {

    set max_awidth [xget_hw_parameter_value $mhsinst "C_PRH_MAX_AWIDTH"]
    set num_peri   [xget_hw_parameter_value $mhsinst "C_NUM_PERIPHERALS"]
    set min "0"

    for {set i 0} {$i < $num_peri} {incr i} {

        set tout_param  [concat C_PRH${i}_RDY_TOUT]
        set tout_value  [xget_hw_parameter_value $mhsinst $tout_param ]
        set wrn_param   [concat C_PRH${i}_WRN_WIDTH]
        set wrn_value   [xget_hw_parameter_value $mhsinst $wrn_param ]
        set rdn_param   [concat C_PRH${i}_RDN_WIDTH]
        set rdn_value   [xget_hw_parameter_value $mhsinst $rdn_param ]
        set rdy_param   [concat C_PRH${i}_RDY_WIDTH]
        set rdy_value   [xget_hw_parameter_value $mhsinst $rdy_param ]
        set sync_param  [concat C_PRH${i}_SYNC]
        set sync_value  [xget_hw_parameter_value $mhsinst $sync_param]
        
        if {$sync_value == 0} {
            if {$wrn_value < $rdn_value} {

                set min $wrn_value

            } else {
    
                set min $rdn_value
           
            }

            if {$rdy_value < $min} {
   
                set min $rdy_value

            } 
                if {$rdy_value == 0 || $rdy_value <=$tout_value} {
            
                set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                error "\nInvalid $instname parameter:\n$rdy_param must be greater than $tout_param at least by one clock period. The $rdy_param is either set to 0 or less than/equal to $tout_param or it is not specified in the MHS file\n" "" "mdt_error"

            }

                if {$tout_value >= $min} {

                set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                error "\nInvalid $instname parameter:\n$tout_param must be less than $wrn_param, $rdn_param, and $rdy_param\n" "" "mdt_error"

            }
        } else {
        
                if {$tout_value == 0} {
            
                set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                error "\nInvalid $instname parameter:\n$tout_param must be greater than 0. The $tout_param is either set to 0 or it is not specified in the MHS file\n" "" "mdt_error"

            }
                if {$rdy_value == 0 || $rdy_value <=$tout_value} {
            
                set instname [xget_hw_parameter_value $mhsinst "INSTANCE"]
                error "\nInvalid $instname parameter:\n$rdy_param must be greater than $tout_param  at least by one clock period. The $rdy_param is either set to 0 or less than/equal to $tout_param or it is not specified in the MHS file\n" "" "mdt_error"

            }

                                
        }
    }

}
