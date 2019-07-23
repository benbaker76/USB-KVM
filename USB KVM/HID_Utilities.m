//
//  HID_Utilities.m
//  USB KVM
//
//  Created by Ben Baker on 6/16/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import "HID_Utilities.h"

void HIDGetUsageName(uint16_t usagePage, uint16_t usage, char *name)
{
	// this allows these definitions to exist in an XML .plist file
	/* 	if (xml_GetUsageName(valueUsagePage, valueUsage, name)) */
	/* 		return; */
	
	switch (usagePage)
	{
		case kHIDPage_Undefined:
			switch (usage)
		{
			default: sprintf (name, "Undefined Page, Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_GenericDesktop:
			switch (usage)
		{
			case kHIDUsage_GD_Pointer: sprintf (name, "Pointer"); break;
			case kHIDUsage_GD_Mouse: sprintf (name, "Mouse"); break;
			case kHIDUsage_GD_Joystick: sprintf (name, "Joystick"); break;
			case kHIDUsage_GD_GamePad: sprintf (name, "GamePad"); break;
			case kHIDUsage_GD_Keyboard: sprintf (name, "Keyboard"); break;
			case kHIDUsage_GD_Keypad: sprintf (name, "Keypad"); break;
			case kHIDUsage_GD_MultiAxisController: sprintf (name, "Multi-Axis Controller"); break;
				
			case kHIDUsage_GD_X: sprintf (name, "X-Axis"); break;
			case kHIDUsage_GD_Y: sprintf (name, "Y-Axis"); break;
			case kHIDUsage_GD_Z: sprintf (name, "Z-Axis"); break;
			case kHIDUsage_GD_Rx: sprintf (name, "X-Rotation"); break;
			case kHIDUsage_GD_Ry: sprintf (name, "Y-Rotation"); break;
			case kHIDUsage_GD_Rz: sprintf (name, "Z-Rotation"); break;
			case kHIDUsage_GD_Slider: sprintf (name, "Slider"); break;
			case kHIDUsage_GD_Dial: sprintf (name, "Dial"); break;
			case kHIDUsage_GD_Wheel: sprintf (name, "Wheel"); break;
			case kHIDUsage_GD_Hatswitch: sprintf (name, "Hatswitch"); break;
			case kHIDUsage_GD_CountedBuffer: sprintf (name, "Counted Buffer"); break;
			case kHIDUsage_GD_ByteCount: sprintf (name, "Byte Count"); break;
			case kHIDUsage_GD_MotionWakeup: sprintf (name, "Motion Wakeup"); break;
			case kHIDUsage_GD_Start: sprintf (name, "Start"); break;
			case kHIDUsage_GD_Select: sprintf (name, "Select"); break;
				
			case kHIDUsage_GD_Vx: sprintf (name, "X-Velocity"); break;
			case kHIDUsage_GD_Vy: sprintf (name, "Y-Velocity"); break;
			case kHIDUsage_GD_Vz: sprintf (name, "Z-Velocity"); break;
			case kHIDUsage_GD_Vbrx: sprintf (name, "X-Rotation Velocity"); break;
			case kHIDUsage_GD_Vbry: sprintf (name, "Y-Rotation Velocity"); break;
			case kHIDUsage_GD_Vbrz: sprintf (name, "Z-Rotation Velocity"); break;
			case kHIDUsage_GD_Vno: sprintf (name, "Vno"); break;
				
			case kHIDUsage_GD_SystemControl: sprintf (name, "System Control"); break;
			case kHIDUsage_GD_SystemPowerDown: sprintf (name, "System Power Down"); break;
			case kHIDUsage_GD_SystemSleep: sprintf (name, "System Sleep"); break;
			case kHIDUsage_GD_SystemWakeUp: sprintf (name, "System Wake Up"); break;
			case kHIDUsage_GD_SystemContextMenu: sprintf (name, "System Context Menu"); break;
			case kHIDUsage_GD_SystemMainMenu: sprintf (name, "System Main Menu"); break;
			case kHIDUsage_GD_SystemAppMenu: sprintf (name, "System App Menu"); break;
			case kHIDUsage_GD_SystemMenuHelp: sprintf (name, "System Menu Help"); break;
			case kHIDUsage_GD_SystemMenuExit: sprintf (name, "System Menu Exit"); break;
			case kHIDUsage_GD_SystemMenu: sprintf (name, "System Menu"); break;
			case kHIDUsage_GD_SystemMenuRight: sprintf (name, "System Menu Right"); break;
			case kHIDUsage_GD_SystemMenuLeft: sprintf (name, "System Menu Left"); break;
			case kHIDUsage_GD_SystemMenuUp: sprintf (name, "System Menu Up"); break;
			case kHIDUsage_GD_SystemMenuDown: sprintf (name, "System Menu Down"); break;
				
			case kHIDUsage_GD_DPadUp: sprintf (name, "DPad Up"); break;
			case kHIDUsage_GD_DPadDown: sprintf (name, "DPad Down"); break;
			case kHIDUsage_GD_DPadRight: sprintf (name, "DPad Right"); break;
			case kHIDUsage_GD_DPadLeft: sprintf (name, "DPad Left"); break;
				
			case kHIDUsage_GD_Reserved: sprintf (name, "Reserved"); break;
				
			default: sprintf (name, "Generic Desktop Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_Simulation:
			switch (usage)
		{
			default: sprintf (name, "Simulation Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_VR:
			switch (usage)
		{
			default: sprintf (name, "VR Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_Sport:
			switch (usage)
		{
			default: sprintf (name, "Sport Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_Game:
			switch (usage)
		{
			default: sprintf (name, "Game Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_KeyboardOrKeypad:
			switch (usage)
		{
			default: sprintf (name, "Keyboard Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_LEDs:
			switch (usage)
		{
				// some LED usages
			case kHIDUsage_LED_IndicatorRed: sprintf (name, "Red LED"); break;
			case kHIDUsage_LED_IndicatorGreen: sprintf (name, "Green LED"); break;
			case kHIDUsage_LED_IndicatorAmber: sprintf (name, "Amber LED"); break;
			case kHIDUsage_LED_GenericIndicator: sprintf (name, "Generic LED"); break;
			case kHIDUsage_LED_SystemSuspend: sprintf (name, "System Suspend LED"); break;
			case kHIDUsage_LED_ExternalPowerConnected: sprintf (name, "External Power LED"); break;
			default: sprintf (name, "LED Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_Button:
			switch (usage)
		{
			default: sprintf (name, "Button #%ud", usage); break;
		}
			break;
		case kHIDPage_Ordinal:
			switch (usage)
		{
			default: sprintf (name, "Ordinal Instance %ux", usage); break;
		}
			break;
		case kHIDPage_Telephony:
			switch (usage)
		{
			default: sprintf (name, "Telephony Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_Consumer:
			switch (usage)
		{
			default: sprintf (name, "Consumer Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_Digitizer:
			switch (usage)
		{
			default: sprintf (name, "Digitizer Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_PID:
			if (((usage >= 0x02) && (usage <= 0x1F)) || ((usage >= 0x29) && (usage <= 0x2F)) ||
				((usage >= 0x35) && (usage <= 0x3F)) || ((usage >= 0x44) && (usage <= 0x4F)) ||
				(usage == 0x8A) || (usage == 0x93)  || ((usage >= 0x9D) && (usage <= 0x9E)) ||
				((usage >= 0xA1) && (usage <= 0xA3)) || ((usage >= 0xAD) && (usage <= 0xFFFF)))
				sprintf (name, "PID Reserved");
			else
				switch (usage)
			{
				case 0x00: sprintf (name, "PID Undefined Usage"); break;
				case kHIDUsage_PID_PhysicalInterfaceDevice: sprintf (name, "Physical Interface Device"); break;
				case kHIDUsage_PID_Normal: sprintf (name, "Normal Force"); break;
					
				case kHIDUsage_PID_SetEffectReport: sprintf (name, "Set Effect Report"); break;
				case kHIDUsage_PID_EffectBlockIndex: sprintf (name, "Effect Block Index"); break;
				case kHIDUsage_PID_ParamBlockOffset: sprintf (name, "Parameter Block Offset"); break;
				case kHIDUsage_PID_ROM_Flag: sprintf (name, "ROM Flag"); break;
					
				case kHIDUsage_PID_EffectType: sprintf (name, "Effect Type"); break;
				case kHIDUsage_PID_ET_ConstantForce: sprintf (name, "Effect Type Constant Force"); break;
				case kHIDUsage_PID_ET_Ramp: sprintf (name, "Effect Type Ramp"); break;
				case kHIDUsage_PID_ET_CustomForceData: sprintf (name, "Effect Type Custom Force Data"); break;
				case kHIDUsage_PID_ET_Square: sprintf (name, "Effect Type Square"); break;
				case kHIDUsage_PID_ET_Sine: sprintf (name, "Effect Type Sine"); break;
				case kHIDUsage_PID_ET_Triangle: sprintf (name, "Effect Type Triangle"); break;
				case kHIDUsage_PID_ET_SawtoothUp: sprintf (name, "Effect Type Sawtooth Up"); break;
				case kHIDUsage_PID_ET_SawtoothDown: sprintf (name, "Effect Type Sawtooth Down"); break;
				case kHIDUsage_PID_ET_Spring: sprintf (name, "Effect Type Spring"); break;
				case kHIDUsage_PID_ET_Damper: sprintf (name, "Effect Type Damper"); break;
				case kHIDUsage_PID_ET_Inertia: sprintf (name, "Effect Type Inertia"); break;
				case kHIDUsage_PID_ET_Friction: sprintf (name, "Effect Type Friction"); break;
				case kHIDUsage_PID_Duration: sprintf (name, "Effect Duration"); break;
				case kHIDUsage_PID_SamplePeriod: sprintf (name, "Effect Sample Period"); break;
				case kHIDUsage_PID_Gain: sprintf (name, "Effect Gain"); break;
				case kHIDUsage_PID_TriggerButton: sprintf (name, "Effect Trigger Button"); break;
				case kHIDUsage_PID_TriggerRepeatInterval: sprintf (name, "Effect Trigger Repeat Interval"); break;
					
				case kHIDUsage_PID_AxesEnable: sprintf (name, "Axis Enable"); break;
				case kHIDUsage_PID_DirectionEnable: sprintf (name, "Direction Enable"); break;
					
				case kHIDUsage_PID_Direction: sprintf (name, "Direction"); break;
					
				case kHIDUsage_PID_TypeSpecificBlockOffset: sprintf (name, "Type Specific Block Offset"); break;
					
				case kHIDUsage_PID_BlockType: sprintf (name, "Block Type"); break;
					
				case kHIDUsage_PID_SetEnvelopeReport: sprintf (name, "Set Envelope Report"); break;
				case kHIDUsage_PID_AttackLevel: sprintf (name, "Envelope Attack Level"); break;
				case kHIDUsage_PID_AttackTime: sprintf (name, "Envelope Attack Time"); break;
				case kHIDUsage_PID_FadeLevel: sprintf (name, "Envelope Fade Level"); break;
				case kHIDUsage_PID_FadeTime: sprintf (name, "Envelope Fade Time"); break;
					
				case kHIDUsage_PID_SetConditionReport: sprintf (name, "Set Condition Report"); break;
				case kHIDUsage_PID_CP_Offset: sprintf (name, "Condition CP Offset"); break;
				case kHIDUsage_PID_PositiveCoefficient: sprintf (name, "Condition Positive Coefficient"); break;
				case kHIDUsage_PID_NegativeCoefficient: sprintf (name, "Condition Negative Coefficient"); break;
				case kHIDUsage_PID_PositiveSaturation: sprintf (name, "Condition Positive Saturation"); break;
				case kHIDUsage_PID_NegativeSaturation: sprintf (name, "Condition Negative Saturation"); break;
				case kHIDUsage_PID_DeadBand: sprintf (name, "Condition Dead Band"); break;
					
				case kHIDUsage_PID_DownloadForceSample: sprintf (name, "Download Force Sample"); break;
				case kHIDUsage_PID_IsochCustomForceEnable: sprintf (name, "Isoch Custom Force Enable"); break;
					
				case kHIDUsage_PID_CustomForceDataReport: sprintf (name, "Custom Force Data Report"); break;
				case kHIDUsage_PID_CustomForceData: sprintf (name, "Custom Force Data"); break;
					
				case kHIDUsage_PID_CustomForceVendorDefinedData: sprintf (name, "Custom Force Vendor Defined Data"); break;
				case kHIDUsage_PID_SetCustomForceReport: sprintf (name, "Set Custom Force Report"); break;
				case kHIDUsage_PID_CustomForceDataOffset: sprintf (name, "Custom Force Data Offset"); break;
				case kHIDUsage_PID_SampleCount: sprintf (name, "Custom Force Sample Count"); break;
					
				case kHIDUsage_PID_SetPeriodicReport: sprintf (name, "Set Periodic Report"); break;
				case kHIDUsage_PID_Offset: sprintf (name, "Periodic Offset"); break;
				case kHIDUsage_PID_Magnitude: sprintf (name, "Periodic Magnitude"); break;
				case kHIDUsage_PID_Phase: sprintf (name, "Periodic Phase"); break;
				case kHIDUsage_PID_Period: sprintf (name, "Periodic Period"); break;
					
				case kHIDUsage_PID_SetConstantForceReport: sprintf (name, "Set Constant Force Report"); break;
					
				case kHIDUsage_PID_SetRampForceReport: sprintf (name, "Set Ramp Force Report"); break;
				case kHIDUsage_PID_RampStart: sprintf (name, "Ramp Start"); break;
				case kHIDUsage_PID_RampEnd: sprintf (name, "Ramp End"); break;
					
				case kHIDUsage_PID_EffectOperationReport: sprintf (name, "Effect Operation Report"); break;
					
				case kHIDUsage_PID_EffectOperation: sprintf (name, "Effect Operation"); break;
				case kHIDUsage_PID_OpEffectStart: sprintf (name, "Op Effect Start"); break;
				case kHIDUsage_PID_OpEffectStartSolo: sprintf (name, "Op Effect Start Solo"); break;
				case kHIDUsage_PID_OpEffectStop: sprintf (name, "Op Effect Stop"); break;
				case kHIDUsage_PID_LoopCount: sprintf (name, "Op Effect Loop Count"); break;
					
				case kHIDUsage_PID_DeviceGainReport: sprintf (name, "Device Gain Report"); break;
				case kHIDUsage_PID_DeviceGain: sprintf (name, "Device Gain"); break;
					
				case kHIDUsage_PID_PoolReport: sprintf (name, "PID Pool Report"); break;
				case kHIDUsage_PID_RAM_PoolSize: sprintf (name, "RAM Pool Size"); break;
				case kHIDUsage_PID_ROM_PoolSize: sprintf (name, "ROM Pool Size"); break;
				case kHIDUsage_PID_ROM_EffectBlockCount: sprintf (name, "ROM Effect Block Count"); break;
				case kHIDUsage_PID_SimultaneousEffectsMax: sprintf (name, "Simultaneous Effects Max"); break;
				case kHIDUsage_PID_PoolAlignment: sprintf (name, "Pool Alignment"); break;
					
				case kHIDUsage_PID_PoolMoveReport: sprintf (name, "PID Pool Move Report"); break;
				case kHIDUsage_PID_MoveSource: sprintf (name, "Move Source"); break;
				case kHIDUsage_PID_MoveDestination: sprintf (name, "Move Destination"); break;
				case kHIDUsage_PID_MoveLength: sprintf (name, "Move Length"); break;
					
				case kHIDUsage_PID_BlockLoadReport: sprintf (name, "PID Block Load Report"); break;
					
				case kHIDUsage_PID_BlockLoadStatus: sprintf (name, "Block Load Status"); break;
				case kHIDUsage_PID_BlockLoadSuccess: sprintf (name, "Block Load Success"); break;
				case kHIDUsage_PID_BlockLoadFull: sprintf (name, "Block Load Full"); break;
				case kHIDUsage_PID_BlockLoadError: sprintf (name, "Block Load Error"); break;
				case kHIDUsage_PID_BlockHandle: sprintf (name, "Block Handle"); break;
					
				case kHIDUsage_PID_BlockFreeReport: sprintf (name, "PID Block Free Report"); break;
					
				case kHIDUsage_PID_TypeSpecificBlockHandle: sprintf (name, "Type Specific Block Handle"); break;
					
				case kHIDUsage_PID_StateReport: sprintf (name, "PID State Report"); break;
				case kHIDUsage_PID_EffectPlaying: sprintf (name, "Effect Playing"); break;
					
				case kHIDUsage_PID_DeviceControlReport: sprintf (name, "PID Device Control Report"); break;
					
				case kHIDUsage_PID_DeviceControl: sprintf (name, "PID Device Control"); break;
				case kHIDUsage_PID_DC_EnableActuators: sprintf (name, "Device Control Enable Actuators"); break;
				case kHIDUsage_PID_DC_DisableActuators: sprintf (name, "Device Control Disable Actuators"); break;
				case kHIDUsage_PID_DC_StopAllEffects: sprintf (name, "Device Control Stop All Effects"); break;
				case kHIDUsage_PID_DC_DeviceReset: sprintf (name, "Device Control Reset"); break;
				case kHIDUsage_PID_DC_DevicePause: sprintf (name, "Device Control Pause"); break;
				case kHIDUsage_PID_DC_DeviceContinue: sprintf (name, "Device Control Continue"); break;
				case kHIDUsage_PID_DevicePaused: sprintf (name, "Device Paused"); break;
				case kHIDUsage_PID_ActuatorsEnabled: sprintf (name, "Actuators Enabled"); break;
				case kHIDUsage_PID_SafetySwitch: sprintf (name, "Safety Switch"); break;
				case kHIDUsage_PID_ActuatorOverrideSwitch: sprintf (name, "Actuator Override Switch"); break;
				case kHIDUsage_PID_ActuatorPower: sprintf (name, "Actuator Power"); break;
				case kHIDUsage_PID_StartDelay: sprintf (name, "Start Delay"); break;
					
				case kHIDUsage_PID_ParameterBlockSize: sprintf (name, "Parameter Block Size"); break;
				case kHIDUsage_PID_DeviceManagedPool: sprintf (name, "Device Managed Pool"); break;
				case kHIDUsage_PID_SharedParameterBlocks: sprintf (name, "Shared Parameter Blocks"); break;
					
				case kHIDUsage_PID_CreateNewEffectReport: sprintf (name, "Create New Effect Report"); break;
				case kHIDUsage_PID_RAM_PoolAvailable: sprintf (name, "RAM Pool Available"); break;
				default: sprintf (name, "PID Usage 0x%ux", usage); break;
			}
			break;
		case kHIDPage_Unicode:
			switch (usage)
		{
			default: sprintf (name, "Unicode Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_PowerDevice:
			if (((usage >= 0x06) && (usage <= 0x0F)) || ((usage >= 0x26) && (usage <= 0x2F)) ||
				((usage >= 0x39) && (usage <= 0x3F)) || ((usage >= 0x48) && (usage <= 0x4F)) ||
				((usage >= 0x58) && (usage <= 0x5F)) || (usage == 0x6A) ||
				((usage >= 0x74) && (usage <= 0xFC)))
				sprintf (name, "Power Device Reserved");
			else
				switch (usage)
			{
				case kHIDUsage_PD_Undefined: sprintf (name, "Power Device Undefined Usage"); break;
				case kHIDUsage_PD_iName: sprintf (name, "Power Device Name Index"); break;
				case kHIDUsage_PD_PresentStatus: sprintf (name, "Power Device Present Status"); break;
				case kHIDUsage_PD_ChangedStatus: sprintf (name, "Power Device Changed Status"); break;
				case kHIDUsage_PD_UPS: sprintf (name, "Uninterruptible Power Supply"); break;
				case kHIDUsage_PD_PowerSupply: sprintf (name, "Power Supply"); break;
					
				case kHIDUsage_PD_BatterySystem: sprintf (name, "Battery System Power Module"); break;
				case kHIDUsage_PD_BatterySystemID: sprintf (name, "Battery System ID"); break;
				case kHIDUsage_PD_Battery: sprintf (name, "Battery"); break;
				case kHIDUsage_PD_BatteryID: sprintf (name, "Battery ID"); break;
				case kHIDUsage_PD_Charger: sprintf (name, "Charger"); break;
				case kHIDUsage_PD_ChargerID: sprintf (name, "Charger ID"); break;
				case kHIDUsage_PD_PowerConverter: sprintf (name, "Power Converter Power Module"); break;
				case kHIDUsage_PD_PowerConverterID: sprintf (name, "Power Converter ID"); break;
				case kHIDUsage_PD_OutletSystem: sprintf (name, "Outlet System power module"); break;
				case kHIDUsage_PD_OutletSystemID: sprintf (name, "Outlet System ID"); break;
				case kHIDUsage_PD_Input: sprintf (name, "Power Device Input"); break;
				case kHIDUsage_PD_InputID: sprintf (name, "Power Device Input ID"); break;
				case kHIDUsage_PD_Output: sprintf (name, "Power Device Output"); break;
				case kHIDUsage_PD_OutputID: sprintf (name, "Power Device Output ID"); break;
				case kHIDUsage_PD_Flow: sprintf (name, "Power Device Flow"); break;
				case kHIDUsage_PD_FlowID: sprintf (name, "Power Device Flow ID"); break;
				case kHIDUsage_PD_Outlet: sprintf (name, "Power Device Outlet"); break;
				case kHIDUsage_PD_OutletID: sprintf (name, "Power Device Outlet ID"); break;
				case kHIDUsage_PD_Gang: sprintf (name, "Power Device Gang"); break;
				case kHIDUsage_PD_GangID: sprintf (name, "Power Device Gang ID"); break;
				case kHIDUsage_PD_PowerSummary: sprintf (name, "Power Device Power Summary"); break;
				case kHIDUsage_PD_PowerSummaryID: sprintf (name, "Power Device Power Summary ID"); break;
					
				case kHIDUsage_PD_Voltage: sprintf (name, "Power Device Voltage"); break;
				case kHIDUsage_PD_Current: sprintf (name, "Power Device Current"); break;
				case kHIDUsage_PD_Frequency: sprintf (name, "Power Device Frequency"); break;
				case kHIDUsage_PD_ApparentPower: sprintf (name, "Power Device Apparent Power"); break;
				case kHIDUsage_PD_ActivePower: sprintf (name, "Power Device RMS Power"); break;
				case kHIDUsage_PD_PercentLoad: sprintf (name, "Power Device Percent Load"); break;
				case kHIDUsage_PD_Temperature: sprintf (name, "Power Device Temperature"); break;
				case kHIDUsage_PD_Humidity: sprintf (name, "Power Device Humidity"); break;
				case kHIDUsage_PD_BadCount: sprintf (name, "Power Device Bad Condition Count"); break;
					
				case kHIDUsage_PD_ConfigVoltage: sprintf (name, "Power Device Nominal Voltage"); break;
				case kHIDUsage_PD_ConfigCurrent: sprintf (name, "Power Device Nominal Current"); break;
				case kHIDUsage_PD_ConfigFrequency: sprintf (name, "Power Device Nominal Frequency"); break;
				case kHIDUsage_PD_ConfigApparentPower: sprintf (name, "Power Device Nominal Apparent Power"); break;
				case kHIDUsage_PD_ConfigActivePower: sprintf (name, "Power Device Nominal RMS Power"); break;
				case kHIDUsage_PD_ConfigPercentLoad: sprintf (name, "Power Device Nominal Percent Load"); break;
				case kHIDUsage_PD_ConfigTemperature: sprintf (name, "Power Device Nominal Temperature"); break;
					
				case kHIDUsage_PD_ConfigHumidity: sprintf (name, "Power Device Nominal Humidity"); break;
				case kHIDUsage_PD_SwitchOnControl: sprintf (name, "Power Device Switch On Control"); break;
				case kHIDUsage_PD_SwitchOffControl: sprintf (name, "Power Device Switch Off Control"); break;
				case kHIDUsage_PD_ToggleControl: sprintf (name, "Power Device Toogle Sequence Control"); break;
				case kHIDUsage_PD_LowVoltageTransfer: sprintf (name, "Power Device Min Transfer Voltage"); break;
				case kHIDUsage_PD_HighVoltageTransfer: sprintf (name, "Power Device Max Transfer Voltage"); break;
				case kHIDUsage_PD_DelayBeforeReboot: sprintf (name, "Power Device Delay Before Reboot"); break;
				case kHIDUsage_PD_DelayBeforeStartup: sprintf (name, "Power Device Delay Before Startup"); break;
				case kHIDUsage_PD_DelayBeforeShutdown: sprintf (name, "Power Device Delay Before Shutdown"); break;
				case kHIDUsage_PD_Test: sprintf (name, "Power Device Test Request/Result"); break;
				case kHIDUsage_PD_ModuleReset: sprintf (name, "Power Device Reset Request/Result"); break;
				case kHIDUsage_PD_AudibleAlarmControl: sprintf (name, "Power Device Audible Alarm Control"); break;
					
				case kHIDUsage_PD_Present: sprintf (name, "Power Device Present"); break;
				case kHIDUsage_PD_Good: sprintf (name, "Power Device Good"); break;
				case kHIDUsage_PD_InternalFailure: sprintf (name, "Power Device Internal Failure"); break;
				case kHIDUsage_PD_VoltageOutOfRange: sprintf (name, "Power Device Voltage Out Of Range"); break;
				case kHIDUsage_PD_FrequencyOutOfRange: sprintf (name, "Power Device Frequency Out Of Range"); break;
				case kHIDUsage_PD_Overload: sprintf (name, "Power Device Overload"); break;
				case kHIDUsage_PD_OverCharged: sprintf (name, "Power Device Over Charged"); break;
				case kHIDUsage_PD_OverTemperature: sprintf (name, "Power Device Over Temperature"); break;
				case kHIDUsage_PD_ShutdownRequested: sprintf (name, "Power Device Shutdown Requested"); break;
					
				case kHIDUsage_PD_ShutdownImminent: sprintf (name, "Power Device Shutdown Imminent"); break;
				case kHIDUsage_PD_SwitchOnOff: sprintf (name, "Power Device On/Off Switch Status"); break;
				case kHIDUsage_PD_Switchable: sprintf (name, "Power Device Switchable"); break;
				case kHIDUsage_PD_Used: sprintf (name, "Power Device Used"); break;
				case kHIDUsage_PD_Boost: sprintf (name, "Power Device Boosted"); break;
				case kHIDUsage_PD_Buck: sprintf (name, "Power Device Bucked"); break;
				case kHIDUsage_PD_Initialized: sprintf (name, "Power Device Initialized"); break;
				case kHIDUsage_PD_Tested: sprintf (name, "Power Device Tested"); break;
				case kHIDUsage_PD_AwaitingPower: sprintf (name, "Power Device Awaiting Power"); break;
				case kHIDUsage_PD_CommunicationLost: sprintf (name, "Power Device Communication Lost"); break;
					
				case kHIDUsage_PD_iManufacturer: sprintf (name, "Power Device Manufacturer String Index"); break;
				case kHIDUsage_PD_iProduct: sprintf (name, "Power Device Product String Index"); break;
				case kHIDUsage_PD_iserialNumber: sprintf (name, "Power Device Serial Number String Index"); break;
				default: sprintf (name, "Power Device Usage 0x%ux", usage); break;
			}
			break;
		case kHIDPage_BatterySystem:
			if (((usage >= 0x0A) && (usage <= 0x0F)) || ((usage >= 0x1E) && (usage <= 0x27)) ||
				((usage >= 0x30) && (usage <= 0x3F)) || ((usage >= 0x4C) && (usage <= 0x5F)) ||
				((usage >= 0x6C) && (usage <= 0x7F)) || ((usage >= 0x90) && (usage <= 0xBF)) ||
				((usage >= 0xC3) && (usage <= 0xCF)) || ((usage >= 0xDD) && (usage <= 0xEF)) ||
				((usage >= 0xF2) && (usage <= 0xFF)))
				sprintf (name, "Power Device Reserved");
			else
				switch (usage)
			{
				case kHIDUsage_BS_Undefined: sprintf (name, "Battery System Undefined"); break;
				case kHIDUsage_BS_SMBBatteryMode: sprintf (name, "SMB Mode"); break;
				case kHIDUsage_BS_SMBBatteryStatus: sprintf (name, "SMB Status"); break;
				case kHIDUsage_BS_SMBAlarmWarning: sprintf (name, "SMB Alarm Warning"); break;
				case kHIDUsage_BS_SMBChargerMode: sprintf (name, "SMB Charger Mode"); break;
				case kHIDUsage_BS_SMBChargerStatus: sprintf (name, "SMB Charger Status"); break;
				case kHIDUsage_BS_SMBChargerSpecInfo: sprintf (name, "SMB Charger Extended Status"); break;
				case kHIDUsage_BS_SMBSelectorState: sprintf (name, "SMB Selector State"); break;
				case kHIDUsage_BS_SMBSelectorPresets: sprintf (name, "SMB Selector Presets"); break;
				case kHIDUsage_BS_SMBSelectorInfo: sprintf (name, "SMB Selector Info"); break;
				case kHIDUsage_BS_OptionalMfgFunction1: sprintf (name, "Battery System Optional SMB Mfg Function 1"); break;
				case kHIDUsage_BS_OptionalMfgFunction2: sprintf (name, "Battery System Optional SMB Mfg Function 2"); break;
				case kHIDUsage_BS_OptionalMfgFunction3: sprintf (name, "Battery System Optional SMB Mfg Function 3"); break;
				case kHIDUsage_BS_OptionalMfgFunction4: sprintf (name, "Battery System Optional SMB Mfg Function 4"); break;
				case kHIDUsage_BS_OptionalMfgFunction5: sprintf (name, "Battery System Optional SMB Mfg Function 5"); break;
				case kHIDUsage_BS_ConnectionToSMBus: sprintf (name, "Battery System Connection To System Management Bus"); break;
				case kHIDUsage_BS_OutputConnection: sprintf (name, "Battery System Output Connection Status"); break;
				case kHIDUsage_BS_ChargerConnection: sprintf (name, "Battery System Charger Connection"); break;
				case kHIDUsage_BS_BatteryInsertion: sprintf (name, "Battery System Battery Insertion"); break;
				case kHIDUsage_BS_Usenext: sprintf (name, "Battery System Use Next"); break;
				case kHIDUsage_BS_OKToUse: sprintf (name, "Battery System OK To Use"); break;
				case kHIDUsage_BS_BatterySupported: sprintf (name, "Battery System Battery Supported"); break;
				case kHIDUsage_BS_SelectorRevision: sprintf (name, "Battery System Selector Revision"); break;
				case kHIDUsage_BS_ChargingIndicator: sprintf (name, "Battery System Charging Indicator"); break;
				case kHIDUsage_BS_ManufacturerAccess: sprintf (name, "Battery System Manufacturer Access"); break;
				case kHIDUsage_BS_RemainingCapacityLimit: sprintf (name, "Battery System Remaining Capacity Limit"); break;
				case kHIDUsage_BS_RemainingTimeLimit: sprintf (name, "Battery System Remaining Time Limit"); break;
				case kHIDUsage_BS_AtRate: sprintf (name, "Battery System At Rate..."); break;
				case kHIDUsage_BS_CapacityMode: sprintf (name, "Battery System Capacity Mode"); break;
				case kHIDUsage_BS_BroadcastToCharger: sprintf (name, "Battery System Broadcast To Charger"); break;
				case kHIDUsage_BS_PrimaryBattery: sprintf (name, "Battery System Primary Battery"); break;
				case kHIDUsage_BS_ChargeController: sprintf (name, "Battery System Charge Controller"); break;
				case kHIDUsage_BS_TerminateCharge: sprintf (name, "Battery System Terminate Charge"); break;
				case kHIDUsage_BS_TerminateDischarge: sprintf (name, "Battery System Terminate Discharge"); break;
				case kHIDUsage_BS_BelowRemainingCapacityLimit: sprintf (name, "Battery System Below Remaining Capacity Limit"); break;
				case kHIDUsage_BS_RemainingTimeLimitExpired: sprintf (name, "Battery System Remaining Time Limit Expired"); break;
				case kHIDUsage_BS_Charging: sprintf (name, "Battery System Charging"); break;
				case kHIDUsage_BS_Discharging: sprintf (name, "Battery System Discharging"); break;
				case kHIDUsage_BS_FullyCharged: sprintf (name, "Battery System Fully Charged"); break;
				case kHIDUsage_BS_FullyDischarged: sprintf (name, "Battery System Fully Discharged"); break;
				case kHIDUsage_BS_ConditioningFlag: sprintf (name, "Battery System Conditioning Flag"); break;
				case kHIDUsage_BS_AtRateOK: sprintf (name, "Battery System At Rate OK"); break;
				case kHIDUsage_BS_SMBErrorCode: sprintf (name, "Battery System SMB Error Code"); break;
				case kHIDUsage_BS_NeedReplacement: sprintf (name, "Battery System Need Replacement"); break;
				case kHIDUsage_BS_AtRateTimeToFull: sprintf (name, "Battery System At Rate Time To Full"); break;
				case kHIDUsage_BS_AtRateTimeToEmpty: sprintf (name, "Battery System At Rate Time To Empty"); break;
				case kHIDUsage_BS_AverageCurrent: sprintf (name, "Battery System Average Current"); break;
				case kHIDUsage_BS_Maxerror: sprintf (name, "Battery System Max Error"); break;
				case kHIDUsage_BS_RelativeStateOfCharge: sprintf (name, "Battery System Relative State Of Charge"); break;
				case kHIDUsage_BS_AbsoluteStateOfCharge: sprintf (name, "Battery System Absolute State Of Charge"); break;
				case kHIDUsage_BS_RemainingCapacity: sprintf (name, "Battery System Remaining Capacity"); break;
				case kHIDUsage_BS_FullChargeCapacity: sprintf (name, "Battery System Full Charge Capacity"); break;
				case kHIDUsage_BS_RunTimeToEmpty: sprintf (name, "Battery System Run Time To Empty"); break;
				case kHIDUsage_BS_AverageTimeToEmpty: sprintf (name, "Battery System Average Time To Empty"); break;
				case kHIDUsage_BS_AverageTimeToFull: sprintf (name, "Battery System Average Time To Full"); break;
				case kHIDUsage_BS_CycleCount: sprintf (name, "Battery System Cycle Count"); break;
				case kHIDUsage_BS_BattPackModelLevel: sprintf (name, "Battery System Batt Pack Model Level"); break;
				case kHIDUsage_BS_InternalChargeController: sprintf (name, "Battery System Internal Charge Controller"); break;
				case kHIDUsage_BS_PrimaryBatterySupport: sprintf (name, "Battery System Primary Battery Support"); break;
				case kHIDUsage_BS_DesignCapacity: sprintf (name, "Battery System Design Capacity"); break;
				case kHIDUsage_BS_SpecificationInfo: sprintf (name, "Battery System Specification Info"); break;
				case kHIDUsage_BS_ManufacturerDate: sprintf (name, "Battery System Manufacturer Date"); break;
				case kHIDUsage_BS_SerialNumber: sprintf (name, "Battery System Serial Number"); break;
				case kHIDUsage_BS_iManufacturerName: sprintf (name, "Battery System Manufacturer Name Index"); break;
				case kHIDUsage_BS_iDevicename: sprintf (name, "Battery System Device Name Index"); break;
				case kHIDUsage_BS_iDeviceChemistry: sprintf (name, "Battery System Device Chemistry Index"); break;
				case kHIDUsage_BS_ManufacturerData: sprintf (name, "Battery System Manufacturer Data"); break;
				case kHIDUsage_BS_Rechargable: sprintf (name, "Battery System Rechargable"); break;
				case kHIDUsage_BS_WarningCapacityLimit: sprintf (name, "Battery System Warning Capacity Limit"); break;
				case kHIDUsage_BS_CapacityGranularity1: sprintf (name, "Battery System Capacity Granularity 1"); break;
				case kHIDUsage_BS_CapacityGranularity2: sprintf (name, "Battery System Capacity Granularity 2"); break;
				case kHIDUsage_BS_iOEMInformation: sprintf (name, "Battery System OEM Information Index"); break;
				case kHIDUsage_BS_InhibitCharge: sprintf (name, "Battery System Inhibit Charge"); break;
				case kHIDUsage_BS_EnablePolling: sprintf (name, "Battery System Enable Polling"); break;
				case kHIDUsage_BS_ResetToZero: sprintf (name, "Battery System Reset To Zero"); break;
				case kHIDUsage_BS_ACPresent: sprintf (name, "Battery System AC Present"); break;
				case kHIDUsage_BS_BatteryPresent: sprintf (name, "Battery System Battery Present"); break;
				case kHIDUsage_BS_PowerFail: sprintf (name, "Battery System Power Fail"); break;
				case kHIDUsage_BS_AlarmInhibited: sprintf (name, "Battery System Alarm Inhibited"); break;
				case kHIDUsage_BS_ThermistorUnderRange: sprintf (name, "Battery System Thermistor Under Range"); break;
				case kHIDUsage_BS_ThermistorHot: sprintf (name, "Battery System Thermistor Hot"); break;
				case kHIDUsage_BS_ThermistorCold: sprintf (name, "Battery System Thermistor Cold"); break;
				case kHIDUsage_BS_ThermistorOverRange: sprintf (name, "Battery System Thermistor Over Range"); break;
				case kHIDUsage_BS_VoltageOutOfRange: sprintf (name, "Battery System Voltage Out Of Range"); break;
				case kHIDUsage_BS_CurrentOutOfRange: sprintf (name, "Battery System Current Out Of Range"); break;
				case kHIDUsage_BS_CurrentNotRegulated: sprintf (name, "Battery System Current Not Regulated"); break;
				case kHIDUsage_BS_VoltageNotRegulated: sprintf (name, "Battery System Voltage Not Regulated"); break;
				case kHIDUsage_BS_MasterMode: sprintf (name, "Battery System Master Mode"); break;
				case kHIDUsage_BS_ChargerSelectorSupport: sprintf (name, "Battery System Charger Support Selector"); break;
				case kHIDUsage_BS_ChargerSpec: sprintf (name, "attery System Charger Specification"); break;
				case kHIDUsage_BS_Level2: sprintf (name, "Battery System Charger Level 2"); break;
				case kHIDUsage_BS_Level3: sprintf (name, "Battery System Charger Level 3"); break;
				default: sprintf (name, "Battery System Usage 0x%ux", usage); break;
			}
			break;
		case kHIDPage_AlphanumericDisplay:
			switch (usage)
		{
			default: sprintf (name, "Alphanumeric Display Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_BarCodeScanner:
			switch (usage)
		{
			default: sprintf (name, "Bar Code Scanner Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_Scale:
			switch (usage)
		{
			default: sprintf (name, "Scale Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_CameraControl:
			switch (usage)
		{
			default: sprintf (name, "Camera Control Usage 0x%ux", usage); break;
		}
			break;
		case kHIDPage_Arcade:
			switch (usage)
		{
			default: sprintf (name, "Arcade Usage 0x%ux", usage); break;
		}
			break;
		default:
			if (usagePage > kHIDPage_VendorDefinedStart)
				sprintf (name, "Vendor Defined Usage 0x%ux", usage);
			else
				sprintf (name, "Page: 0x%ux, Usage: 0x%ux", usagePage, usage);
			break;
	}
}
