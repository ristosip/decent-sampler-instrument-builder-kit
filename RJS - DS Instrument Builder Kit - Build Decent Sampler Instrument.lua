-- This script is a part of 'Decent Sampler Instrument Builder Kit'.
-- Running the script builds contents of a Decent Sampler preset file.
--
-- Copyright (C) 2021 Risto Sipola
-- 'Decent Sampler Instrument Builder Kit' script collection is licensed under the GNU General Public License v3.0: See LICENSE
--
-- Note: 'Decent Sampler Instrument Builder Kit' is designed to work in conjunction with 'RJS Sampling Suite'.
--
-- How to use:         1. Preparations: Arrange the samples using 'RJS Sampling Suite'.
--                     2. Run the script. (Use a marker as an input command if needed.)
--                     3. Copy the text from the message window that opens.
--                     4. Paste the text into an empty text file and save the file ( [name].dspreset ).
--
-- Input Command:      'ds [instrument name] [options]'
--
--                      - If no input command is given the default build command is used.
--                
--                      - [instrument name]: No functionality yet. This parameter can be omitted.

--                      - [options]: List the features you want to add to the instrument.
--                        * Available features: 
--                                             ** reverb - Adds a reverb.
--                                             ** filter - Adds a (low pass) filter.
--                                             ** adsr - Adds all four knobs if the default settings allow. See the settings below.
--                                             ** attack - Adds only the 'attack' knob. 'adsr' overrides this option.
--                                             ** decay - Adds only the 'decay' knob.'adsr' overrides this option.
--                                             ** release - Adds only the 'release' knob.'adsr' overrides this option.                                           
--                                             ** micvol - Adds volume faders for each microphone (of a multi mic recording).
--
--                      - Examples:            "ds MyInstrumentName reverb filter adsr micvol"       - Adds all available features.
--                                             "ds reverb filter attack release"
--                                             "ds reverb micvol" 
--
--                                             Features/knobs/bindings are added if the default settings allow. See and modify the settings below.
--
-- author: Risto Sipola

----------------------
-- DEFAULT SETTINGS --
----------------------

fileFormat = ".wav"
default_sample_folder_path = "Samples/" -- must end with "/"
default_resource_folder_path = "Samples/" -- must end with "/"
use_group_specific_sub_folders_for_samples = true -- use in accordance with reaper's render settings

default_build_command = "ds DefaultName reverb filter adsr micvol"

-- Parameter options
-- [instrument name]
-- reverb
-- filter
-- adsr
-- attack
-- decay
-- release
-- micvol

-------- UI ---------
default_coverArt_file_name = "coverart.png" -- use an empty string "" if you don't want a cover art image
default_bgImage_file_name = "background.png" -- use an empty string "" if you don't want a background image
default_bgColor = "00000000"
default_textColor = "FF000000"
default_ui_width = 812
default_ui_heigth = 375
default_tab_name = "Main"
default_label_width = 50
default_label_height = 30
default_knob_y_pos = 0

-- What knobs/controls should be put on the UI
default_want_mic_vol_knobs = true
default_want_reverb_knob = true
default_want_lp_filter_knob = true
default_want_adsr_knobs = true
default_want_midi_cc_filter_binding = true
default_midi_cc_num = 1

-- Some color options:
--
-- Black (solid): FF000000
-- Black (90% transparency): E6000000
-- Red (solid): FFFF0000
-- Red (50% transparency): 80FF0000
-- Blue (solid): FF0000FF

-------- Amp --------
default_global_volume = 1.0 -- <groups> level setting
default_global_tuning = 0 -- <groups> level setting
default_global_panning = 0 -- <groups> level setting
default_ampVelTrack = 0.5
default_group_volume = 1.0
default_group_pan = 0
default_group_tuning = 0
default_mic_volume = 0.8 -- range 0.0 - 1.0
default_use_group_level_mic_tags = true
default_use_groups_level_amp_vel_tracking = true
default_use_groups_level_volume = true
default_use_groups_level_pan = true
default_use_groups_level_tuning = true

-- Legato/Monophonic
default_silencingMode = "normal"

-- Looping
default_loopCrossfade = 2400
default_loopCrossfadeMode = "linear"

-- ASDR
default_use_groups_level_adsr = true -- the adsr values will be assigned to groups level, the adsr parameters will not appear on group level
default_group_attack = 0.001
default_group_decay = 0.0
default_group_sustain = 1
default_group_release = 0.050

-- Effect parameters --
-- LP filter
default_lp_filter_resonance = 0.7
default_lp_filter_frequency = 10000
default_lp_filter_knob_max_freq = 22000 
default_lp_filter_knob_min_freq = 60 
default_lp_filter_binding_max_freq = 5000 -- use these to set the range controlled by a midi cc
default_lp_filter_binding_min_freq = 60
default_lp_filter_binding_translation = "linear" -- a non-linear translation would be useful but not available at this time
-- Reverb
default_reverb_roomSize = 0.7
default_reverb_damping = 0.3
default_reverb_wetLevel = 0.3

-------- Other --------
default_seqMode = "round_robin" -- in case of round robins. otherwise "always".

indent_char = " " -- affects how lines are indented in the preset file. for human-readibility.

------------------------

function parse_input_command()

	local command = {}
	local parameter_count = 0
	local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
	local identifier_found = false
	for j = 0, num_markers + num_regions - 1, 1 do
		local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(j)

		for word in string.gmatch(name, "%a+") do 
			if word == "ds" then
				identifier_found = true
				break;
			end
		end
		if identifier_found then
			for word in string.gmatch(name, "%a+") do 
				if word ~= "ds" then				
					parameter_count = parameter_count + 1
					command[parameter_count] = word
				end
			end
			break;
		end
	end	
	if identifier_found == false then
		for word in string.gmatch(default_build_command, "%a+") do 
			if word ~= "ds" then				
				parameter_count = parameter_count + 1
				command[parameter_count] = word
			end
		end
	end

	return command, parameter_count
end

function parse_group_info_for_rr_num(group_info)
	local num1
	local num2
	local rr_num
	local digit_counter = 0
	
	local identifier_found = false
	
	for word in string.gmatch(group_info, "%a+") do 
		if string.find(word, "RR") ~= nil then
			identifier_found = true
			break;
		end
	end
	if identifier_found then
		for word in string.gmatch(group_info, "%d+") do 
			digit_counter = digit_counter + 1
			if digit_counter == 1 then
				num1 = tonumber(word)
			end
			if digit_counter == 2 then
				num2 = tonumber(word)
			end
		end
		
		if num2 ~= nil then
			rr_num = num2
		else
			rr_num = num1
		end
	end
	return rr_num
end

function parse_group_info_for_mic_num(group_info)
	local num1
	local num2
	local mic_num
	local digit_counter = 0
	
	local identifier_found = false
	
	for word in string.gmatch(group_info, "%a+") do 
		if string.find(word, "Mic") ~= nil then
			identifier_found = true
			break;
		end
	end
	if identifier_found then
		for word in string.gmatch(group_info, "%d+") do 
			digit_counter = digit_counter + 1
			if digit_counter == 1 then
				num1 = tonumber(word)
			end
			if digit_counter == 2 then
				num2 = tonumber(word)
			end
		end
		
		if num2 ~= nil then
			mic_num = num1
		else
			mic_num = num1
		end
	end
	return mic_num
end

function parse_notes_for_loop_info(notes)
	local loop = false
	local loop_start
	local loop_end
	local loop_crossfade
	local sub_strings = {}
	local sub_strings_idx = 0
	local comma_idx = 0
	local digit_counter = 0
	local loop_counter = 0
	
	while comma_idx ~= nil do
		comma_idx = string.find(notes, ",", 1) 
		if comma_idx ~= nil then
			sub_strings_idx = sub_strings_idx + 1
			sub_strings[sub_strings_idx] = string.sub(notes, 1, comma_idx)  
			notes = string.gsub(notes, sub_strings[sub_strings_idx], "")			
		else
			if notes ~= nil then
				sub_strings_idx = sub_strings_idx + 1
				sub_strings[sub_strings_idx] = notes
			end
		end
		loop_counter = loop_counter + 1
		if loop_counter > 100 then
			reaper.ShowConsoleMsg("Got stuck in while parsing loop info. If you used '-' in the item notes, that caused the problem. Use letter 'n' for a negative sign instead. For instance, minus four, n4.")
			loop_counter = 0
			break;
		end
	end
	local identifier_found = false
	for i = 1, sub_strings_idx, 1 do
		for word in string.gmatch(sub_strings[i], "%a+") do 
			if string.find(word, "loop") ~= nil then
				identifier_found = true
				break;
			end
		end
		if identifier_found then
			for word in string.gmatch(sub_strings[i], "%d+") do 
				digit_counter = digit_counter + 1
				if digit_counter == 1 then
					loop_start = tonumber(word)
					loop = true
				end
				if digit_counter == 2 then
					loop_end = tonumber(word)
				end
				if digit_counter == 3 then
					loop_crossfade = tonumber(word)/1000
				end
			end
			break -- loop info found
		end
	end
	return loop, loop_start, loop_end, loop_crossfade
end

function parse_notes_for_legato_info(notes)
	local legato = false
	local legato_interval
	local legato_group_attack
	local legato_group_decay
	local legato_group_sustain
	local legato_group_release
	local sub_strings = {}
	local sub_strings_idx = 0
	local comma_idx = 0
	local digit_counter = 0
	local loop_counter = 0
	
	while comma_idx ~= nil do
		comma_idx = string.find(notes, ",", 1) 
		if comma_idx ~= nil then
			sub_strings_idx = sub_strings_idx + 1
			sub_strings[sub_strings_idx] = string.sub(notes, 1, comma_idx)  
			notes = string.gsub(notes, sub_strings[sub_strings_idx], "")			
		else
			if notes ~= nil then
				sub_strings_idx = sub_strings_idx + 1
				sub_strings[sub_strings_idx] = notes
			end
		end
		loop_counter = loop_counter + 1
		if loop_counter > 100 then
			reaper.ShowConsoleMsg("Got stuck in while parsing legato info. If you used '-' in the item notes, that caused the problem. Use letter 'n' for a negative sign instead. For instance, minus four, n4.")
			loop_counter = 0
			break;
		end
	end
	local identifier_found = false
	for i = 1, sub_strings_idx, 1 do
		for word in string.gmatch(sub_strings[i], "%a+") do 
			if string.find(word, "legato") ~= nil and string.find(word, "legatosustain") == nil then
				identifier_found = true
				break;
			end
		end
		if identifier_found then
			for word in string.gmatch(sub_strings[i], "%d+") do 
				digit_counter = digit_counter + 1
				if digit_counter == 1 then
					legato_interval = tonumber(word) -- need to check and include sign??
					for w in string.gmatch(sub_strings[i], ".+") do 
						if string.find(w, "n"..word) ~= nil then
							legato_interval = (-1) * legato_interval
						end
					end
				end
				if digit_counter == 2 then
					legato_group_attack = tonumber(word)/1000
				end
				if digit_counter == 3 then
					legato_group_decay = tonumber(word)/1000
				end
				if digit_counter == 4 then
					legato_group_sustain = tonumber(word)/100
				end
				if digit_counter == 5 then
					legato_group_release = tonumber(word)/1000
				end
			end
			legato = true
			break -- legato info found
		end
	end
	return legato, legato_interval, legato_group_attack, legato_group_decay, legato_group_sustain, legato_group_release
end

function parse_notes_for_legatosustain_info(notes)
	local legato_sustain = false
	local legato_sustain_group_attack
	local legato_sustain_group_decay
	local legato_sustain_group_sustain
	local legato_sustain_group_release
	local sub_strings = {}
	local sub_strings_idx = 0
	local comma_idx = 0
	local digit_counter = 0
	local loop_counter = 0

	while comma_idx ~= nil do
		comma_idx = string.find(notes, ",", 1) 
		if comma_idx ~= nil then
			sub_strings_idx = sub_strings_idx + 1
			sub_strings[sub_strings_idx] = string.sub(notes, 1, comma_idx)  
			notes = string.gsub(notes, sub_strings[sub_strings_idx], "")			
		else
			if notes ~= nil then
				sub_strings_idx = sub_strings_idx + 1
				sub_strings[sub_strings_idx] = notes
			end
		end
		loop_counter = loop_counter + 1
		if loop_counter > 100 then
			reaper.ShowConsoleMsg("Got stuck in while parsing legatosustain info. If you used '-' in the item notes, that caused the problem. Use letter 'n' for a negative sign instead. For instance, minus four, n4.")
			loop_counter = 0
			break;
		end
	end
	local identifier_found = false
	for i = 1, sub_strings_idx, 1 do
		for word in string.gmatch(sub_strings[i], "%a+") do 
			if string.find(word, "legatosustain") ~= nil then
				identifier_found = true
				
			end
		end
		if identifier_found then
			for word in string.gmatch(sub_strings[i], "%d+") do 
				digit_counter = digit_counter + 1
				if digit_counter == 1 then
					legato_sustain_group_attack = tonumber(word)/1000
				end
				if digit_counter == 2 then
					legato_sustain_group_decay = tonumber(word)/1000
				end
				if digit_counter == 3 then
					legato_sustain_group_sustain = tonumber(word)/100
				end
				if digit_counter == 4 then
					legato_sustain_group_release = tonumber(word)/1000
				end
			end	
			legato_sustain = true			
			break 
		end
	end
	return legato_sustain, legato_sustain_group_attack, legato_sustain_group_decay, legato_sustain_group_sustain, legato_sustain_group_release
end

function parse_notes_for_sustain_info(notes)
	local sustain = false
	local sustain_group_attack
	local sustain_group_decay
	local sustain_group_sustain
	local sustain_group_release
	local sub_strings = {}
	local sub_strings_idx = 0
	local comma_idx = 0
	local digit_counter = 0
	local loop_counter = 0

	while comma_idx ~= nil do
		comma_idx = string.find(notes, ",", 1) 
		if comma_idx ~= nil then
			sub_strings_idx = sub_strings_idx + 1
			sub_strings[sub_strings_idx] = string.sub(notes, 1, comma_idx)  
			notes = string.gsub(notes, sub_strings[sub_strings_idx], "")			
		else
			if notes ~= nil then
				sub_strings_idx = sub_strings_idx + 1
				sub_strings[sub_strings_idx] = notes
			end
		end
		loop_counter = loop_counter + 1
		if loop_counter > 100 then
			reaper.ShowConsoleMsg("Got stuck in while parsing sustain info. If you used '-' in the item notes, that caused the problem. Use letter 'n' for a negative sign instead. For instance, minus four, n4.")
			loop_counter = 0
			break;
		end
	end
	local identifier_found = false
	for i = 1, sub_strings_idx, 1 do
		for word in string.gmatch(sub_strings[i], "%a+") do 
			if string.find(word, "sustain") ~= nil and string.find(word, "legatosustain") == nil then
				identifier_found = true
				
			end
		end
		if identifier_found then
			for word in string.gmatch(sub_strings[i], "%d+") do 
				digit_counter = digit_counter + 1
				if digit_counter == 1 then
					sustain_group_attack = tonumber(word)/1000
				end
				if digit_counter == 2 then
					sustain_group_decay = tonumber(word)/1000
				end
				if digit_counter == 3 then
					sustain_group_sustain = tonumber(word)/100
				end
				if digit_counter == 4 then
					sustain_group_release = tonumber(word)/1000
				end
			end	
			sustain = true			
			break 
		end
	end
	return sustain, sustain_group_attack, sustain_group_decay, sustain_group_sustain, sustain_group_release
end

function parse_notes_for_start_info(notes)
	local sample_start
	local sub_strings = {}
	local sub_strings_idx = 0
	local comma_idx = 0
	local digit_counter = 0
	local loop_counter = 0
	
	while comma_idx ~= nil do
		comma_idx = string.find(notes, ",", 1) 
		if comma_idx ~= nil then
			sub_strings_idx = sub_strings_idx + 1
			sub_strings[sub_strings_idx] = string.sub(notes, 1, comma_idx)  
			notes = string.gsub(notes, sub_strings[sub_strings_idx], "")			
		else
			if notes ~= nil then
				sub_strings_idx = sub_strings_idx + 1
				sub_strings[sub_strings_idx] = notes
			end
		end
		loop_counter = loop_counter + 1
		if loop_counter > 100 then
			reaper.ShowConsoleMsg("Got stuck in while parsing start info. If you used '-' in the item notes, that caused the problem. Use letter 'n' for a negative sign instead. For instance, minus four, n4.")
			loop_counter = 0
			break;
		end
	end
	local identifier_found = false
	for i = 1, sub_strings_idx, 1 do
		for word in string.gmatch(sub_strings[i], "%a+") do 
			if string.find(word, "start") ~= nil then
				identifier_found = true
				break;
			end
		end
		if identifier_found then
			for word in string.gmatch(sub_strings[i], "%d+") do 
				digit_counter = digit_counter + 1
				if digit_counter == 1 then
					sample_start = tonumber(word)
				end
			end
			sustain_return = true
			break -- start time info found
		end
	end
	return sample_start
end

function append_tags_with_mic_info(tags_string, group_info)

	local mic_num = parse_group_info_for_mic_num(group_info)
	
	if mic_num ~= -1 then
		local comma = ","		
		if tags_string == "" then
			comma = ""
		end		
		tags_string = tags_string..comma.."mic"..mic_num
	end
	return tags_string

end

function append_tags(tags_string, new_tag)
	local comma = ","		
	if tags_string == "" then
		comma = ""
	end		
	tags_string = tags_string..comma..new_tag
	return tags_string
end

function tags_include_word(tags, word)
	local tag_found = false
	for w in string.gmatch(tags, "%a+") do 
		if string.find(w, word) ~= nil then
			tag_found = true
			break;
		end
	end
	return tag_found
end

function parse_track_name(track_name)
	local loVel
	local hiVel
	local digit_counter = 0
	
	for word in string.gmatch(track_name, "%d+") do 
		digit_counter = digit_counter + 1
		if digit_counter == 1 then
			loVel = tonumber(word)
		end
		if digit_counter == 2 then
			hiVel = tonumber(word)
		end
	end
	
	return loVel, hiVel
end

function parse_region_name(region_name)
	local rootNote
	local loNote
	local hiNote
	local digit_counter = 0
	
	for word in string.gmatch(region_name, "%d+") do 
		digit_counter = digit_counter + 1
		if digit_counter == 1 then
			loNote = tonumber(word)
		end
		if digit_counter == 2 then
			rootNote = tonumber(word)
		end
		if digit_counter == 3 then
			hiNote = tonumber(word)
		end
	end
	
	return loNote, rootNote, hiNote
end

function get_region_name(item)
	local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
	local ret_name = ""
	for i = 0, num_markers + num_regions - 1, 1 do
		local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
		if isrgn then
			if math.abs(pos - item_pos) < 0.01 then
				ret_name = name
			end
		end
	end
	return ret_name
end

function add_top_level_element(ds_preset_string, indent_amount)
	local line = ""
	local indent = ""

	line = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>".."\n"
	line = line.."<DecentSampler>"
	
	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string..indent..line
	
	return ds_preset_string
end

function add_ui_element(ds_preset_string, indent_amount)
	local line = ""
	local indent = ""
	local coverArt = default_coverArt_file_name
	local bgImage = default_bgImage_file_name
	local folder_path = default_resource_folder_path
	local bgColor = default_bgColor
	local width = default_ui_width
	local height = default_ui_heigth
	
	line = "<ui "
	if coverArt ~= nil and coverArt ~= "" then
		line = line.."coverArt=".."\""..folder_path..coverArt.."\" "
	end
	if bgImage ~= nil and bgImage ~= "" then
	line = line.."bgImage=".."\""..folder_path..bgImage.."\" "
	end
	line = line.."bgColor=".."\""..bgColor.."\" "
	line = line.."width=".."\""..width.."\" "
	line = line.."height=".."\""..height.."\" "
	
	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line..">"
	
	return ds_preset_string
end

function add_tab_element(ds_preset_string, indent_amount)
	local line = ""
	local indent = ""
	local name = default_tab_name
	
	line = "<tab name=".."\""..name.."\""
	
	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line..">"
	
	return ds_preset_string
end

function add_label_element(ds_preset_string, indent_amount, x, y, width, height, text)
	local line = ""
	local indent = ""
	
	line = "<label "
	line = line.."x=".."\""..x.."\" "
	line = line.."y=".."\""..y.."\" "
	line = line.."width=".."\""..width.."\" "
	line = line.."height=".."\""..height.."\" "
	line = line.."text=".."\""..text.."\" "
	
	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line..">"
	
	return ds_preset_string
end

function add_labeled_knob_element(ds_preset_string, indent_amount, x, y, label, type_, minValue, maxValue, textColor, value)
	local line = ""
	local indent = ""
	
	line = "<labeled-knob "
	line = line.."x=".."\""..x.."\" "
	line = line.."y=".."\""..y.."\" "
	line = line.."label=".."\""..label.."\" "
	line = line.."type=".."\""..type_.."\" "
	line = line.."minValue=".."\""..minValue.."\" "
	line = line.."maxValue=".."\""..maxValue.."\" "
	line = line.."textColor=".."\""..textColor.."\" "
	line = line.."value=".."\""..value.."\" "
	
	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line..">"
	
	return ds_preset_string
end

function add_control_element(ds_preset_string, indent_amount, x, y, parameterName, style, type_, minValue, maxValue, textColor, value)
	local line = ""
	local indent = ""
	
	line = "<control "
	line = line.."x=".."\""..x.."\" "
	line = line.."y=".."\""..y.."\" "
	line = line.."parameterName=".."\""..parameterName.."\" "
	line = line.."style=".."\""..style.."\" "
	line = line.."type=".."\""..type_.."\" "
	line = line.."minValue=".."\""..minValue.."\" "
	line = line.."maxValue=".."\""..maxValue.."\" "
	line = line.."textColor=".."\""..textColor.."\" "
	line = line.."value=".."\""..value.."\" "
	
	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line..">"
	
	return ds_preset_string
end

function add_groups_element(ds_preset_string, indent_amount)
	local line = ""
	local indent = ""
	local volume = default_global_volume
	local pan = default_global_panning
	local globalTuning = default_global_tuning
	local ampVelTrack = default_ampVelTrack
	local attack = default_group_attack
	local decay = default_group_decay
	local sustain = default_group_sustain
	local release = default_group_release
	
	line = "<groups "
	
	if default_use_groups_level_volume then
		line = line.."volume=".."\""..volume.."\" "
	end
	
	if default_use_groups_level_pan then
		line = line.."pan=".."\""..pan.."\" "
	end
	
	if default_use_groups_level_tuning then
		line = line.."globalTuning=".."\""..globalTuning.."\" "
	end
	
	if default_use_groups_level_amp_vel_tracking then
		line = line.."ampVelTrack=".."\""..ampVelTrack.."\" "
	end
	
	if default_use_groups_level_adsr then
		line = line.."attack=".."\""..attack.."\" "
		line = line.."decay=".."\""..decay.."\" "
		line = line.."sustain=".."\""..sustain.."\" "
		line = line.."release=".."\""..release.."\" "
	end
	
	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line..">"
	
	return ds_preset_string
end

function add_group_element(ds_preset_string, indent_amount, trigger, seqPosition, do_loop, loopCrossfade, tags, attack, decay, sustain, release, silencedByTags, silencingMode, previousNotes, legatoInterval)
	local line = ""
	local indent = ""
	local volume = default_group_volume
	local pan = default_group_pan
	local groupTuning = default_group_tuning
	local ampVelTrack = default_ampVelTrack
	local seqMode = default_seqMode
	
	if attack == nil then
		attack = default_group_attack
	end
	if decay == nil then
		decay = default_group_decay
	end
	if sustain == nil then
		sustain = default_group_sustain
	end
	if release == nil then
		release = default_group_release
	end
	
	line = "<group "
	
	if not default_use_groups_level_volume then
		line = line.."volume=".."\""..volume.."\" "
	end
	
	if not default_use_groups_level_pan then
		line = line.."pan=".."\""..pan.."\" "
	end
	
	if not default_use_groups_level_amp_vel_tracking then
		line = line.."ampVelTrack=".."\""..ampVelTrack.."\" "
	end
	
	if not default_use_groups_level_tuning then
		line = line.."groupTuning=".."\""..groupTuning.."\" "
	end
	
	if not default_use_groups_level_adsr or tags_include_word(tags, "legato") or tags_include_word(tags, "sustain") then
		line = line.."attack=".."\""..attack.."\" "
		line = line.."decay=".."\""..decay.."\" "
		line = line.."sustain=".."\""..sustain.."\" "
		line = line.."release=".."\""..release.."\" "
	end
	
	if trigger ~= nil then
		line = line.."trigger=".."\""..trigger.."\" "
	end
	
	if seqPosition ~= nil then
		line = line.."seqPosition=".."\""..seqPosition.."\" "
		line = line.."seqMode=".."\""..seqMode.."\" "
	end
		
	if loopCrossfade ~= nil then
		line = line.."loopCrossfade=".."\""..loopCrossfade.."\" "
		line = line.."loopCrossfadeMode=".."\""..default_loopCrossfadeMode.."\" "
	elseif do_loop and loopCrossfade == nil then
		line = line.."loopCrossfade=".."\""..default_loopCrossfade.."\" "
		line = line.."loopCrossfadeMode=".."\""..default_loopCrossfadeMode.."\" "
	end
	
	if tags ~= nil and tags ~= "" then
		line = line.."tags=".."\""..tags.."\" "
	end
		
	if silencedByTags ~= nil then
		line = line.."silencedByTags=".."\""..silencedByTags.."\" "
	end
	
	if silencingMode ~= nil then
		line = line.."silencingMode=".."\""..silencingMode.."\" "
	end
	
	if previousNotes ~= nil then
		line = line.."previousNotes=".."\""..previousNotes.."\" "
	end
	
	if legatoInterval ~= nil then
		line = line.."legatoInterval=".."\""..legatoInterval.."\" "
	end
		
	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line..">"
	
	return ds_preset_string
end

function add_sample_element(ds_preset_string, indent_amount, group_info, rootNote, loNote, hiNote, loVel, hiVel, start, end_, tags, do_loop, loopStart, loopEnd, loopCrossfade, silencedByTags, silencingMode, legatoInterval, previousNotes)
	local line = ""
	local indent = ""
	local folder_path = default_sample_folder_path
	
	line = "<sample path=".."\""..folder_path
	
	if use_group_specific_sub_folders_for_samples then
		line = line..group_info.."/" --folder
	end
	
	line = line..group_info.."_"..loNote.."_"..rootNote.."_"..hiNote.."_"..loVel.."_"..hiVel..fileFormat.."\" " --file
	
	line = line.."rootNote=".."\""..rootNote.."\" "
	line = line.."loNote=".."\""..loNote.."\" "
	line = line.."hiNote=".."\""..hiNote.."\" "
	line = line.."loVel=".."\""..loVel.."\" "
	line = line.."hiVel=".."\""..hiVel.."\" "
	if start ~= nil then
		line = line.."start=".."\""..start.."\" "
	end
	if end_ ~= nil then
		line = line.."end=".."\""..end_.."\" "
	end
	if tags ~= nil and tags ~= "" then
		line = line.."tags=".."\""..tags.."\" "
	end
	if do_loop ~= nil and do_loop then	
		if loopStart ~= nil then
			line = line.."loopStart=".."\""..loopStart.."\" "
		end
		if loopEnd ~= nil then
			line = line.."loopEnd=".."\""..loopEnd.."\" "
		end
		if loopCrossfade ~= nil then
			line = line.."loopCrossfade=".."\""..loopCrossfade.."\" "
		end
		line = line.."loopEnabled=".."\"".."true".."\" "
	end
	
	if silencedByTags ~= nil then
		line = line.."silencedByTags=".."\""..silencedByTags.."\" "
	end
	if silencingMode ~= nil then
		line = line.."silencingMode=".."\""..silencingMode.."\" "
	end
	if legatoInterval ~= nil then
		line = line.."legatoInterval=".."\""..legatoInterval.."\" "
	end
	if previousNotes ~= nil then
		line = line.."previousNotes=".."\""..previousNotes.."\" "
	end
	
	line = line.."/>"
	
	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line

	return ds_preset_string
end

function add_effects_element(ds_preset_string, indent_amount)
	local line = ""
	local indent = ""
	
	line = "<effects"

	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line..">"
	
	return ds_preset_string
end

function add_effect_element(ds_preset_string, indent_amount, effect_type)
	local line = ""
	local indent = ""
	
	line = "<effect "
	line = line.."type=".."\""..effect_type.."\" "
	
	if effect_type == "reverb" then
		line = line.."roomSize=".."\""..default_reverb_roomSize.."\" "
		line = line.."damping=".."\""..default_reverb_damping.."\" "
		line = line.."wetLevel=".."\""..default_reverb_wetLevel.."\" "
	elseif effect_type == "lowpass_4pl" then
		line = line.."resonance=".."\""..default_lp_filter_resonance.."\" "
		line = line.."frequency=".."\""..default_lp_filter_frequency.."\" "
	else

	end
			
	line = line.."/>"		
			
	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line
	
	return ds_preset_string
end

function add_midi_element(ds_preset_string, indent_amount)
	local line = ""
	local indent = ""
	
	line = "<midi"
	
	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line..">"
	
	return ds_preset_string
end

function add_cc_element(ds_preset_string, indent_amount, cc_number)
	local line = ""
	local indent = ""
	
    line = "<cc "
	line = line.."number=".."\""..cc_number.."\" "

	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line..">"
	
	return ds_preset_string
end

function add_tags_element(ds_preset_string, indent_amount)
	local line = ""
	local indent = ""
	
	line = "<tags"

	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line..">"
	
	return ds_preset_string
end

function add_tag_element(ds_preset_string, indent_amount, name, volume, polyphony)
	local line = ""
	local indent = ""
	
    line = "<tag "
	
	if name ~= nil then
		line = line.."name=".."\""..name.."\" "	
	end
	
	if volume ~= nil then
		line = line.."volume=".."\""..volume.."\" "	
	end
	if polyphony ~= nil then
		line = line.."polyphony=".."\""..polyphony.."\" "	
	end
	
	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line..">"
	
	return ds_preset_string
end

function add_binding_element(ds_preset_string, indent_amount, type_, level, position, identifier, parameter, translation, translationOutputMin, translationOutputMax, translationReversed, translationTable)
	local line = ""
	local indent = ""
	
	line = "<binding "
	line = line.."type=".."\""..type_.."\" "	
	line = line.."level=".."\""..level.."\" "
	line = line.."position=".."\""..position.."\" "
	line = line.."identifier=".."\""..identifier.."\" "
	line = line.."parameter=".."\""..parameter.."\" "
	
	if translation ~= nil then
		line = line.."translation=".."\""..translation.."\" "	
	end
	
	if translationOutputMin ~= nil then
		line = line.."translationOutputMin=".."\""..translationOutputMin.."\" "	
	end
	
	if translationOutputMax ~= nil then
		line = line.."translationOutputMax=".."\""..translationOutputMax.."\" "	
	end
	
	if translationReversed ~= nil then
		line = line.."translationReversed=".."\""..translationReversed.."\" "	
	end
	
	if translationTable ~= nil then
		line = line.."translationTable=".."\""..translationTable.."\" "	
	end
	
	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line.."/>"
	
	return ds_preset_string
end

function add_element_closing_line(ds_preset_string, indent_amount, element_type)
	local indent = ""
	local line = ""
	
	line = "</"..element_type..">"

	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line

	return ds_preset_string
end

function add_comment_line(ds_preset_string, indent_amount, comment)
	local indent = ""
	local line = ""
	
	line = "<!-- "..comment.."-->"

	for i = 0, indent_amount - 1, 1 do
		indent = indent..indent_char
	end
	
	ds_preset_string = ds_preset_string.."\n"..indent..line

	return ds_preset_string
end

function is_included_in_command(word, command, parameter_count)
	local is_included = false
	for i = 1, parameter_count, 1 do
		if command[i] == word then
			is_included = true
			break;
		end
	end
	return is_included
end

function calculate_knob_x_position_increment(command, parameter_count, mic_count)
	local knob_count = 0
	local x_increment = -1
	
	if is_included_in_command("reverb", command, parameter_count) and default_want_reverb_knob then
		knob_count  = knob_count + 1
	end
	if is_included_in_command("filter", command, parameter_count) and default_want_lp_filter_knob then
		knob_count  = knob_count + 1
	end
	if is_included_in_command("adsr", command, parameter_count) and default_want_adsr_knobs then
		knob_count  = knob_count + 4
	else
		if is_included_in_command("attack", command, parameter_count) and default_want_adsr_knobs then
			knob_count  = knob_count + 1
		end
		if is_included_in_command("release", command, parameter_count) and default_want_adsr_knobs then
			knob_count  = knob_count + 1
		end
		if is_included_in_command("decay", command, parameter_count) and default_want_adsr_knobs then
			knob_count  = knob_count + 1
		end
	end
	if is_included_in_command("micvol", command, parameter_count) and default_want_mic_vol_knobs then
		knob_count  = knob_count + mic_count
	end
	
	x_increment = math.floor(default_ui_width / (knob_count + 1))
	
	return x_increment
end

function add_knobs_and_controls(ds_preset_string, indent_amount, command, parameter_count, mic_count)
	
	local includes_adsr = is_included_in_command("adsr", command, parameter_count)
	local x_increment = calculate_knob_x_position_increment(command, parameter_count, mic_count)
	local x = 0
	local knob_position = 0
	
	for i = 1, parameter_count, 1 do
		local parameter = command[i]
		
		if parameter == "reverb" and default_want_reverb_knob then
			x = x + x_increment
			ds_preset_string = add_labeled_knob_element(ds_preset_string, indent_amount, x, default_knob_y_pos, "Reverb", "float", 0, 1, default_textColor, default_reverb_wetLevel)
			ds_preset_string =  add_binding_element(ds_preset_string, indent_amount + 1, "effect", "instrument", knob_position, "reverb", "FX_REVERB_WET_LEVEL")
			knob_position = knob_position + 1
			ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "labeled-knob")
		elseif parameter == "filter" and default_want_lp_filter_knob then
			x = x + x_increment
			ds_preset_string = add_labeled_knob_element(ds_preset_string, indent_amount, x, default_knob_y_pos, "LP Filter", "float", default_lp_filter_knob_min_freq, default_lp_filter_knob_max_freq, default_textColor, default_lp_filter_frequency)
			ds_preset_string =  add_binding_element(ds_preset_string, indent_amount + 1, "effect", "instrument", knob_position, "filter", "FX_FILTER_FREQUENCY")
			knob_position = knob_position + 1
			ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "labeled-knob")
		elseif parameter == "adsr" and default_want_adsr_knobs then
			-- A
			x = x + x_increment
			ds_preset_string = add_labeled_knob_element(ds_preset_string, indent_amount, x, default_knob_y_pos, "Attack", "float", 0.0, 2.0, default_textColor, default_group_attack)
			ds_preset_string =  add_binding_element(ds_preset_string, indent_amount + 1, "amp", "instrument", knob_position, "attack", "ENV_ATTACK")
			knob_position = knob_position + 1
			ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "labeled-knob")
			-- D
			x = x + x_increment
			ds_preset_string = add_labeled_knob_element(ds_preset_string, indent_amount, x, default_knob_y_pos, "Decay", "float", 0.0, 2.0, default_textColor, default_group_decay)
			ds_preset_string =  add_binding_element(ds_preset_string, indent_amount + 1, "amp", "instrument", knob_position, "decay", "ENV_DECAY")
			knob_position = knob_position + 1
			ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "labeled-knob")
			-- S
			x = x + x_increment
			ds_preset_string = add_labeled_knob_element(ds_preset_string, indent_amount, x, default_knob_y_pos, "Sustain", "float", 0.0, 1.0, default_textColor, default_group_sustain)
			ds_preset_string =  add_binding_element(ds_preset_string, indent_amount + 1, "amp", "instrument", knob_position, "sustain", "ENV_SUSTAIN")
			knob_position = knob_position + 1
			ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "labeled-knob")
			-- R
			x = x + x_increment
			ds_preset_string = add_labeled_knob_element(ds_preset_string, indent_amount, x, default_knob_y_pos, "Release", "float", 0.0, 2.0, default_textColor, default_group_release)
			ds_preset_string =  add_binding_element(ds_preset_string, indent_amount + 1, "amp", "instrument", knob_position, "release", "ENV_RELEASE")
			knob_position = knob_position + 1
			ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "labeled-knob")
		elseif parameter == "attack" and default_want_adsr_knobs and not includes_adsr then
			-- A
			x = x + x_increment
			ds_preset_string = add_labeled_knob_element(ds_preset_string, indent_amount, x, default_knob_y_pos, "Attack", "float", 0.0, 2.0, default_textColor, default_group_attack)
			ds_preset_string =  add_binding_element(ds_preset_string, indent_amount + 1, "amp", "instrument", knob_position, "attack", "ENV_ATTACK")
			knob_position = knob_position + 1
			ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "labeled-knob")
		elseif parameter == "decay" and default_want_adsr_knobs and not includes_adsr then
			-- D
			x = x + x_increment
			ds_preset_string = add_labeled_knob_element(ds_preset_string, indent_amount, x, default_knob_y_pos, "Decay", "float", 0.0, 2.0, default_textColor, default_group_decay)
			ds_preset_string =  add_binding_element(ds_preset_string, indent_amount + 1, "amp", "instrument", knob_position, "decay", "ENV_DECAY")
			knob_position = knob_position + 1
			ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "labeled-knob")
		elseif parameter == "release" and default_want_adsr_knobs and not includes_adsr then
			-- R
			x = x + x_increment
			ds_preset_string = add_labeled_knob_element(ds_preset_string, indent_amount, x, default_knob_y_pos, "Release", "float", 0.0, 2.0, default_textColor, default_group_release)
			ds_preset_string =  add_binding_element(ds_preset_string, indent_amount + 1, "amp", "instrument", knob_position, "release", "ENV_RELEASE")
			knob_position = knob_position + 1
			ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "labeled-knob")
		elseif parameter == "micvol" and default_want_mic_vol_knobs then
			for j = 1, mic_count, 1 do
				x = x + x_increment
				ds_preset_string = add_control_element(ds_preset_string, indent_amount, x, default_knob_y_pos, "Mic "..j, "linear_bar_vertical", "float", 0, 1, default_textColor, default_mic_volume)
				ds_preset_string =  add_binding_element(ds_preset_string, indent_amount + 1, "amp", "tag", knob_position, "mic"..j, "AMP_VOLUME")
				knob_position = knob_position + 1
				ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "control")
			end
		end
	end
	return ds_preset_string
end

function get_knob_position(knob_type, command, parameter_count, mic_count)
	local knob_count = 0
	local search_successful = false
	for i = 1, parameter_count, 1 do
		local parameter = command[i]
		
		if parameter == "reverb" and default_want_reverb_knob then
			knob_count = knob_count + 1
		elseif parameter == "filter" and default_want_lp_filter_knob then
			knob_count = knob_count + 1
		elseif parameter == "adsr" and default_want_adsr_knobs then
			knob_count = knob_count + 4
		elseif parameter == "attack" and default_want_adsr_knobs and not includes_adsr then
			knob_count = knob_count + 1
		elseif parameter == "decay" and default_want_adsr_knobs and not includes_adsr then
			knob_count = knob_count + 1
		elseif parameter == "release" and default_want_adsr_knobs and not includes_adsr then
			knob_count = knob_count + 1
		elseif parameter == "micvol" and default_want_mic_vol_knobs then
			for j = 1, mic_count, 1 do
				knob_count = knob_count + 1
			end
		end
		if parameter == knob_type then
			search_successful = true
			break -- search completed
		end
	end
	if search_successful then
		return knob_count - 1
	else
		return -1
	end
end

function get_effect_position(effect_type, command, parameter_count)
	local effect_count = 0
	local search_successful = false
	for i = 1, parameter_count, 1 do
		local parameter = command[i]
		
		if parameter == "reverb" then
			effect_count = effect_count + 1
		elseif parameter == "filter" then
			effect_count = effect_count + 1
		end
		if parameter == effect_type then
			search_successful = true
			break -- search completed
		end
	end
	if search_successful then
		return effect_count - 1
	else
		return -1
	end
end

function add_effects(ds_preset_string, indent_amount, command, parameter_count)
	
	for i = 1, parameter_count, 1 do
		local parameter = command[i]
		
		if parameter == "reverb" then
			ds_preset_string = add_effect_element(ds_preset_string, indent_amount, "reverb")
		elseif parameter == "filter" then
			ds_preset_string = add_effect_element(ds_preset_string, indent_amount, "lowpass_4pl")
		end
	end
	return ds_preset_string
end

function count_mics(group_names, group_count)
	local max_mic_num = 0
	
	for i = 1, group_count, 1 do
		local group_name = group_names[i]
		local mic_num = parse_group_info_for_mic_num(group_name)
		if mic_num > max_mic_num then
			max_mic_num = mic_num
		end
	end
	return max_mic_num
end

function build_instrument(command, parameter_count)
	local ds_preset_string = ""
	local groups_string = ""
	local group_string = ""
	local group_names = {}
	local group_count = 0
	local indent_amount = 0
	
	-- preprocess groups to be able to utilize group information with bindings
	indent_amount = 3
	local first_track_idx = reaper.GetMediaTrackInfo_Value(reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0)), "IP_TRACKNUMBER") - 1
	local num_tracks = reaper.CountTracks(0)
	local current_group_name = ""
	local group_loop = false
	local group_legato = false
	local group_legato_interval
	local group_sustain_group = false
	local group_legatosustain = false
	local group_attack, group_decay, group_sustain, group_release
	local group_sample_start
	local group_trigger
	local loop_start, loop_end, loop_crossfade
	local leg_sus_a, leg_sus_d, leg_sus_s, leg_sus_r
	local sus_a, sus_d, sus_s, sus_r
		
	for i = first_track_idx, num_tracks - 1, 1 do	
		local track = reaper.GetTrack(0, i)
		local retval, track_name = reaper.GetTrackName(track)
		local num_items = reaper.CountTrackMediaItems(track)
		local mic_num
		
		if num_items > 0 then
			
			for j = 0, num_items - 1, 1 do
				local sample_silencedByTags, sample_silencingMode, sample_legatoInterval, sample_previousNotes
				local item = reaper.GetTrackMediaItem(track, j)
				local retval, group_info = reaper.GetTrackName(reaper.GetParentTrack(track))
				if group_info == nil then
					group_info = ""
				end
				if j == 0 and group_info ~= current_group_name then
					-- add a group
					if i > first_track_idx then
						group_string = add_element_closing_line(group_string, indent_amount - 1, "group")
						groups_string = groups_string..group_string
						if group_sustain_group and group_legatosustain then 
							-- the legato mechanism goes from sustaining to a legato transition and back to sustain samples
							-- thus a modified copy of the sustain group is added
							group_string = string.gsub(group_string, group_info, group_info.." LEGATO-SUSTAIN GROUP")
							group_string = string.gsub(group_string, "trigger=\"first\"", "trigger=\"legato\"")
							group_string = string.gsub(group_string, "silencedByTags=\"legato,sustaingroup\"", "silencedByTags=\"legatosustain\"")
							group_string = string.gsub(group_string, "sustaingroup", "legatosustain")
							group_string = string.gsub(group_string, "attack=".."\""..group_attack.."\"", "attack=".."\""..leg_sus_a.."\"")
							group_string = string.gsub(group_string, "decay=".."\""..group_decay.."\"", "decay=".."\""..leg_sus_d.."\"")
							group_string = string.gsub(group_string, "sustain=".."\""..group_sustain.."\"", "sustain=".."\""..leg_sus_s.."\"")
							group_string = string.gsub(group_string, "release=".."\""..group_release.."\"", "release=".."\""..leg_sus_r.."\"")
							groups_string = groups_string..group_string														
						end
						group_string = ""
					end
					-- init variables					
					group_loop = false
					group_legato = false
					group_legato_interval = nil
					group_sustain_group = false
					group_legatosustain = false
					group_attack = nil 
					group_decay = nil
					group_sustain = nil
					group_release = nil
					group_sample_start = nil
					group_trigger = nil
					loop_start = nil
					loop_length = nil
					loop_crossfade = nil
					sus_a = nil
					sus_d = nil
					sus_s = nil
					sus_r = nil
					--
					mic_num = parse_group_info_for_mic_num(group_info)
					local seqPosition = parse_group_info_for_rr_num(group_info)
					local group_tags = ""
					if default_use_group_level_mic_tags then
						group_tags = append_tags_with_mic_info(group_tags, group_info)
					end	
					-- handle notes
					local leg_a, leg_d, leg_s, leg_r

					local silencedByTags, silencingMode, previousNotes
					retval, notes = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
					group_sample_start = parse_notes_for_start_info(notes)
					group_loop, loop_start, loop_end, loop_crossfade = parse_notes_for_loop_info(notes)
					group_legato, group_legato_interval, leg_a, leg_d, leg_s, leg_r = parse_notes_for_legato_info(notes)
					group_legatosustain, leg_sus_a, leg_sus_d, leg_sus_s, leg_sus_r = parse_notes_for_legatosustain_info(notes)					
					group_sustain_group, sus_a, sus_d, sus_s, sus_r = parse_notes_for_sustain_info(notes)

					if group_legato then
						group_trigger = "legato"
						group_attack = leg_a
						group_decay = leg_d
						group_sustain = leg_s
						group_release = leg_r
						if mic_num == nil then
							group_tags = append_tags(group_tags, "legato") 
							silencedByTags = "legato"
						else
							group_tags = append_tags(group_tags, "legato"..mic_num)
							silencedByTags = "legato"..mic_num
						end
						silencingMode = default_silencingMode
					elseif group_legatosustain and not group_sustain_group then
						group_trigger = "legato"
						group_attack = leg_sus_a
						group_decay = leg_sus_d
						group_sustain = leg_sus_s
						group_release = leg_sus_r						
						group_tags = append_tags(group_tags, "legatosustain") 
						silencedByTags = "legato"					
						silencingMode = default_silencingMode
					elseif group_sustain_group then
						group_trigger = "attack" -- "first"
						if sus_a ~= nil then
							group_attack = sus_a
						else	
							group_attack = default_group_attack
						end
						if sus_d ~= nil then
							group_decay = sus_d
						else	
							group_decay = default_group_decay
						end
						if sus_s ~= nil then
							group_sustain = sus_s
						else	
							group_sustain = default_group_sustain
						end
						if sus_r ~= nil then
							group_release = sus_r
						else	
							group_release = default_group_release
						end
						if mic_num == nil then
							group_tags = append_tags(group_tags, "sustaingroup") 
							silencedByTags = "legato,sustaingroup"
						else
							group_tags = append_tags(group_tags, "sustaingroup"..mic_num) 
							silencedByTags = "legato,sustaingroup"..mic_num
						end
						silencingMode = default_silencingMode
					end
					-- form a group
					group_string = add_comment_line(group_string, indent_amount - 1, "--------------------------------")
					group_string = add_comment_line(group_string, indent_amount - 1, "-----------    "..group_info.."     ")
					group_string = add_comment_line(group_string, indent_amount - 1, "--------------------------------")
					group_string = add_group_element(group_string, indent_amount - 1, group_trigger, seqPosition, group_loop, loop_crossfade, group_tags, group_attack, group_decay, group_sustain, group_release, silencedByTags, silencingMode, previousNotes, group_legato_interval)
					current_group_name = group_info
					group_count = group_count + 1
					group_names[group_count] = current_group_name				
				end
				local sample_tags = current_group_name
				if not default_use_group_level_mic_tags then
					sample_tags = append_tags_with_mic_info(sample_tags, current_group_name)
				end
				local loVel, hiVel = parse_track_name(track_name)
				local loNote, rootNote, hiNote = parse_region_name(get_region_name(item))
				
				local retv, sample_notes = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
				local sample_start = parse_notes_for_start_info(sample_notes)
				local sample_loop, sample_loop_start, sample_loop_end, sample_loop_crossfade = parse_notes_for_loop_info(sample_notes)
				-- if there are no sample specific settings, switch to group specific settings
				if sample_loop == false then
					sample_loop = group_loop
					sample_loop_start = loop_start
					sample_loop_end = loop_end
					sample_loop_crossfade = loop_crossfade
				end
				if sample_start == nil then
					sample_start = group_sample_start
				end
								
				-- add samples under the group
				group_string = add_sample_element(group_string, indent_amount, group_info, rootNote, loNote, hiNote, loVel, hiVel, sample_start, nil, sample_tags, sample_loop, sample_loop_start, sample_loop_end, sample_loop_crossfade, sample_silencedByTags, sample_silencingMode, sample_legatoInterval, sample_previousNotes)
			end
		end
	end
	group_string = add_element_closing_line(group_string, indent_amount - 1, "group")
	groups_string = groups_string..group_string -- add the last group
	if group_sustain_group and group_legatosustain then 
		-- the legato mechanism goes from sustaining to a legato transition and back to sustain samples
		-- thus a modified copy of the sustain group is added
		group_string = string.gsub(group_string, group_info, group_info.." LEGATO-SUSTAIN GROUP")
		group_string = string.gsub(group_string, "trigger=\"first\"", "trigger=\"legato\"")
		group_string = string.gsub(group_string, "silencedByTags=\"legato\"", "silencedByTags=\"legatosustain\"")
		group_string = string.gsub(group_string, "sustaingroup", "legatosustain")
		group_string = string.gsub(group_string, "attack=".."\""..group_attack.."\"", "attack=".."\""..leg_sus_a.."\"")
		group_string = string.gsub(group_string, "release=".."\""..group_release.."\"", "release=".."\""..leg_sus_r.."\"")
		groups_string = groups_string..group_string
	end	
	
	local mic_count = count_mics(group_names, group_count)
	indent_amount = 0
		
	-- top level
	ds_preset_string = add_top_level_element(ds_preset_string, indent_amount)
	
	-- ui
	indent_amount = indent_amount + 1
	ds_preset_string = add_comment_line(ds_preset_string, indent_amount, "--------------------------------")
	ds_preset_string = add_comment_line(ds_preset_string, indent_amount, "-----------    UI     ----------")
	ds_preset_string = add_comment_line(ds_preset_string, indent_amount, "--------------------------------")
	ds_preset_string = add_ui_element(ds_preset_string, indent_amount)
	
	-- tab
	indent_amount = indent_amount + 1
	ds_preset_string = add_tab_element(ds_preset_string, indent_amount)
	
	-- labels, knobs, controls
	indent_amount = indent_amount + 1
	ds_preset_string = add_knobs_and_controls(ds_preset_string, indent_amount, command, parameter_count, mic_count)
	
	-- close tab
	indent_amount = indent_amount -1
	ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "tab")	
	-- close ui
	indent_amount = indent_amount -1
	ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "ui")
	
	-- groups
	ds_preset_string = add_comment_line(ds_preset_string, indent_amount, "--------------------------------")
	ds_preset_string = add_comment_line(ds_preset_string, indent_amount, "-----------  GROUPS   ----------")
	ds_preset_string = add_comment_line(ds_preset_string, indent_amount, "--------------------------------")
	ds_preset_string = add_groups_element(ds_preset_string, indent_amount)
		
	-- group and samples
	indent_amount = indent_amount + 2

	ds_preset_string = ds_preset_string..groups_string
	-- close group
	indent_amount = indent_amount - 1

	-- close groups
	indent_amount = indent_amount - 1
	ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "groups")
	
	-- effects
	ds_preset_string = add_comment_line(ds_preset_string, indent_amount, "--------------------------------")
	ds_preset_string = add_comment_line(ds_preset_string, indent_amount, "-----------  EFFECTS  ----------")
	ds_preset_string = add_comment_line(ds_preset_string, indent_amount, "--------------------------------")
	ds_preset_string = add_effects_element(ds_preset_string, indent_amount)
	
	--effect
	indent_amount = indent_amount + 1
	ds_preset_string = add_effects(ds_preset_string, indent_amount, command, parameter_count)
	
	-- close effects
	indent_amount = indent_amount - 1
	ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "effects")
	
	-- midi
	ds_preset_string = add_comment_line(ds_preset_string, indent_amount, "--------------------------------")
	ds_preset_string = add_comment_line(ds_preset_string, indent_amount, "-----------    MIDI   ----------")
	ds_preset_string = add_comment_line(ds_preset_string, indent_amount, "--------------------------------")
	ds_preset_string = add_midi_element(ds_preset_string, indent_amount)
	
	-- cc
	indent_amount = indent_amount + 1
	if default_want_midi_cc_filter_binding and is_included_in_command("filter", command, parameter_count) then
		ds_preset_string = add_cc_element(ds_preset_string, indent_amount, default_midi_cc_num)
		if default_want_lp_filter_knob then
			ds_preset_string = add_binding_element(ds_preset_string, indent_amount + 1, "labeled_knob", "ui", get_knob_position("filter", command, parameter_count, mic_count), "filter", "value", default_lp_filter_binding_translation, default_lp_filter_binding_min_freq, default_lp_filter_binding_max_freq)
		else
			ds_preset_string = add_binding_element(ds_preset_string, indent_amount + 1, "effect", "instrument", get_effect_position("filter", command, parameter_count), "filter", "FX_FILTER_FREQUENCY", default_lp_filter_binding_translation, default_lp_filter_binding_min_freq, default_lp_filter_binding_max_freq)
		end
		ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "cc")
	end
	
	-- close midi
	indent_amount = indent_amount - 1
	ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "midi")
	
	-- close top level
	indent_amount = indent_amount - 1
	ds_preset_string = add_element_closing_line(ds_preset_string, indent_amount, "DecentSampler")
		
	return ds_preset_string
end

function main()

	local ds_preset_string = ""
	
	if reaper.CountSelectedMediaItems(0) > 0 then
		local command, parameter_count = parse_input_command()
		ds_preset_string = build_instrument(command, parameter_count)				
		reaper.ShowConsoleMsg(ds_preset_string)
	end
	
end

main()