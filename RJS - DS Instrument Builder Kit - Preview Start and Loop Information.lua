-- This script is a part of 'Decent Sampler Instrument Builder Kit'.
-- The script can run in the backround while other scripts are used to setup loops and start points for samples. This script will automatically show loop/start settings for a selected sample.
--
-- Copyright (C) 2021 Risto Sipola
-- 'Decent Sampler Instrument Builder Kit' script collection is licensed under the GNU General Public License v3.0: See LICENSE
--
-- How to use:         1. Run the script.
--                     2. Select a sample. If the sample's start and/or loop info is available, the loop is shown as a time selection and the start point is shown as a marker.
--                     3. Close the window to stop the script.
--
-- Note: 'Decent Sampler Instrument Builder Kit' is designed to work in conjunction with 'RJS Sampling Suite'.
--
-- author: Risto Sipola

current_item_GUID = nil
start_marker_code = 10000

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

function preview_sample_start_and_loop()

	gfx.update()
	local sel_item_count = reaper.CountSelectedMediaItems(0)
	
	if sel_item_count == 1 then
		local item = reaper.GetSelectedMediaItem(0, 0)
		local retval, item_GUID = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
		if item_GUID ~= current_item_GUID then
			current_item_GUID = item_GUID
			local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
			local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
			local take_source = reaper.GetMediaItemTake_Source(reaper.GetTake(item, 0))
			local sample_rate = reaper.GetMediaSourceSampleRate(take_source)
			local retval, item_notes = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
			local loop, loop_start, loop_end, loop_crossfade = parse_notes_for_loop_info(item_notes)
			local sample_start = parse_notes_for_start_info(item_notes)
			if sample_start ~= nil and sample_rate ~= nil and sample_rate ~= 0 then
				local offset_time = sample_start / sample_rate
				local new_cursor_pos = item_pos + offset_time
				reaper.SetEditCurPos(new_cursor_pos, false, false)
				
				local marker_exists = false
				local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)				
				for i = 0, num_markers + num_regions - 1, 1 do
					local  retv, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
					if markrgnindexnumber == start_marker_code then
						marker_exists = true
						break;
					end
				end
				if marker_exists then
					reaper.SetProjectMarker(start_marker_code, false, new_cursor_pos, new_cursor_pos, "Start")
				else
					reaper.AddProjectMarker2(0, false, new_cursor_pos, new_cursor_pos, "Start",  start_marker_code, reaper.ColorToNative(255, 255, 255)|0x1000000)
				end
			end
			if loop and loop_start ~= nil and loop_end ~= nil then
				local offset_loop_start = loop_start / sample_rate
				local offset_loop_end = loop_end / sample_rate
				local loop_start_time = item_pos + offset_loop_start
				local loop_end_time = item_pos + offset_loop_end
				reaper.GetSet_LoopTimeRange(true, false, loop_start_time, loop_end_time, false)
			end
		end
	end
	local char_ = gfx.getchar()
	if char_ ~= -1 then
		reaper.defer(preview_sample_start_and_loop)
	else
		local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)	
		for i = 0, num_markers + num_regions - 1, 1 do
			local  retv, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
			if markrgnindexnumber == start_marker_code then
				reaper.DeleteProjectMarkerByIndex(0, i)
				break
			end
		end		
	end
end

gfx.init("Preview On", 500, 100, 0, 800, 200)
my_str = "Previewing sample start and loop.\nStop by closing this window."
gfx.setfont(1, "Arial", 28)
gfx.x, gfx.y = 20, 20
gfx.drawstr(my_str)
reaper.defer(preview_sample_start_and_loop)