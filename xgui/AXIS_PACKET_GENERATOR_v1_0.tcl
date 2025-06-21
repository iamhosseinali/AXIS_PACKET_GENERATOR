
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/AXIS_PACKET_GENERATOR_v1_0.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "tDATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "PACKET_TO_SEND" -parent ${Page_0}
  ipgui::add_param $IPINST -name "Specific_Number_Of_Packets" -parent ${Page_0}
  ipgui::add_param $IPINST -name "Number_Of_Packets_To_Send" -parent ${Page_0}


}

proc update_PARAM_VALUE.Number_Of_Packets_To_Send { PARAM_VALUE.Number_Of_Packets_To_Send PARAM_VALUE.Specific_Number_Of_Packets } {
	# Procedure called to update Number_Of_Packets_To_Send when any of the dependent parameters in the arguments change
	
	set Number_Of_Packets_To_Send ${PARAM_VALUE.Number_Of_Packets_To_Send}
	set Specific_Number_Of_Packets ${PARAM_VALUE.Specific_Number_Of_Packets}
	set values(Specific_Number_Of_Packets) [get_property value $Specific_Number_Of_Packets]
	if { [gen_USERPARAMETER_Number_Of_Packets_To_Send_ENABLEMENT $values(Specific_Number_Of_Packets)] } {
		set_property enabled true $Number_Of_Packets_To_Send
	} else {
		set_property enabled false $Number_Of_Packets_To_Send
	}
}

proc validate_PARAM_VALUE.Number_Of_Packets_To_Send { PARAM_VALUE.Number_Of_Packets_To_Send } {
	# Procedure called to validate Number_Of_Packets_To_Send
	return true
}

proc update_PARAM_VALUE.PACKET_TO_SEND { PARAM_VALUE.PACKET_TO_SEND } {
	# Procedure called to update PACKET_TO_SEND when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PACKET_TO_SEND { PARAM_VALUE.PACKET_TO_SEND } {
	# Procedure called to validate PACKET_TO_SEND
	return true
}

proc update_PARAM_VALUE.Specific_Number_Of_Packets { PARAM_VALUE.Specific_Number_Of_Packets } {
	# Procedure called to update Specific_Number_Of_Packets when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Specific_Number_Of_Packets { PARAM_VALUE.Specific_Number_Of_Packets } {
	# Procedure called to validate Specific_Number_Of_Packets
	return true
}

proc update_PARAM_VALUE.tDATA_WIDTH { PARAM_VALUE.tDATA_WIDTH } {
	# Procedure called to update tDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.tDATA_WIDTH { PARAM_VALUE.tDATA_WIDTH } {
	# Procedure called to validate tDATA_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.tDATA_WIDTH { MODELPARAM_VALUE.tDATA_WIDTH PARAM_VALUE.tDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.tDATA_WIDTH}] ${MODELPARAM_VALUE.tDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.PACKET_TO_SEND { MODELPARAM_VALUE.PACKET_TO_SEND PARAM_VALUE.PACKET_TO_SEND } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PACKET_TO_SEND}] ${MODELPARAM_VALUE.PACKET_TO_SEND}
}

proc update_MODELPARAM_VALUE.Specific_Number_Of_Packets { MODELPARAM_VALUE.Specific_Number_Of_Packets PARAM_VALUE.Specific_Number_Of_Packets } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.Specific_Number_Of_Packets}] ${MODELPARAM_VALUE.Specific_Number_Of_Packets}
}

proc update_MODELPARAM_VALUE.Number_Of_Packets_To_Send { MODELPARAM_VALUE.Number_Of_Packets_To_Send PARAM_VALUE.Number_Of_Packets_To_Send } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.Number_Of_Packets_To_Send}] ${MODELPARAM_VALUE.Number_Of_Packets_To_Send}
}

