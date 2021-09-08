-- This script is a part of 'Decent Sampler Instrument Builder Kit'.
-- Running the script sets start times for selected items under Reaper's edit cursor.
--
-- Copyright (C) 2021 Risto Sipola
-- 'Decent Sampler Instrument Builder Kit' script collection is licensed under the GNU General Public License v3.0: See LICENSE
--
-- How to use:         1. Select samples/items to edit and place the edit cursor where you want to set the sample playback start point.
--                     2. Run the script.
--                     3. The start info is now written in the item's "notes".
--
-- Note: 'Decent Sampler Instrument Builder Kit' is designed to work in conjunction with 'RJS Sampling Suite'.
--
-- author: Risto Sipola

function replace_notes_start_info(notes, new_start_info)
	local original_notes = notes
	local sub_strings = {}
	local sub_strings_idx = 0
	local comma_idx = 0
	local digit_counter = 0
	
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
			local comma_i = string.find(sub_strings[i], ",", 1)
			if comma_i ~= nil and comma_i ~= 1 then
				notes = string.gsub(original_notes, sub_strings[i], new_start_info..",")
			elseif comma_i ~= nil and comma_i == 1 then
				notes = string.gsub(original_notes, sub_strings[i], ","..new_start_info)
			else
				notes = string.gsub(original_notes, sub_strings[i], new_start_info)
			end
			break
		end
	end
	if not identifier_found then
		notes = original_notes..","..new_start_info
	end
		
	return notes
end

function set_start_info(item, cursor_pos)
	local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	
	if item_pos <= cursor_pos and (item_pos + item_len) >= cursor_pos then
		local take_source = reaper.GetMediaItemTake_Source(reaper.GetTake(item, 0))
		local sample_rate = reaper.GetMediaSourceSampleRate(take_source)
		local sample_start = math.floor((cursor_pos - item_pos) * sample_rate)
		local retval, item_notes = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
		local new_notes = ""
		local new start_info = " start "..sample_start
		if item_notes ~= nil and item_notes ~= "" then
			new_notes = replace_notes_start_info(item_notes, start_info)
		else
			new_notes = start_info			
		end
		reaper.GetSetMediaItemInfo_String(item, "P_NOTES", new_notes, true)
	end
	
end

function main()
	local item_count = reaper.CountSelectedMediaItems(0)
	local cursor_pos = reaper.GetCursorPosition()

	if item_count > 0 and cursor_pos ~= nil then
		for i = 0, item_count - 1, 1 do
			local item = reaper.GetSelectedMediaItem(0, i)
			set_start_info(item, cursor_pos)
		end
	end
end

main()