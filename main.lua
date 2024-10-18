-- Renoise Pulse tool - RePulse
-- author: kejkzz@gmail.com

-- setup script environment
local vb = nil
local dialog = nil

local function show_status(message)
  renoise.app():show_status(message)
  print(message)
end

local options = renoise.Document.create("RePulse") {
  show_debug_prints = false,
  current_pulse = 1,
  rotate_pulse = 0,
  rotate_pulse_fine = 0,
  notes_count = 2
}

local function lowest_common_multiplier(pulse, notes_count)
  local res = pulse % notes_count
  if res == 0 then
    return notes_count
  else
    return lowest_common_multiplier(notes_count, res)
  end    
end

renoise.tool().preferences = options

local function calculate_pulse()
  local song_lines_per_beat = renoise.song().transport.lpb
  local track_note_value = 48
  local volume_value = 40  
  local notes_count = options.notes_count.value + 1
  local current_pulse = math.floor(options.current_pulse.value)
  local current_shift = math.floor(options.rotate_pulse.value)
  local rotate_pulse_fine = math.floor(options.rotate_pulse_fine.value)
  -- select instruments
  local current_instrument = renoise.song().selected_instrument
  local current_phrase = renoise.song().selected_phrase  
  
  -- calculate the number of beats in the phrase
  -- needed to create a perfect circle
  local beat_spacing = song_lines_per_beat * current_pulse
  local new_lines_count = song_lines_per_beat * notes_count * current_pulse
  local lines_per_beat = notes_count * current_pulse
  
  -- set the phrase props
  current_phrase:clear()
  current_phrase.number_of_lines = new_lines_count  
  current_phrase.lpb = lines_per_beat
  current_phrase.delay_column_visible = true
  
  -- Fill notes  
  for i = 1 + current_shift, new_lines_count, beat_spacing  do
    local current_line = current_phrase:line(i)
    local current_note = current_line:note_column(1)
    current_note.note_value = track_note_value
    current_note.delay_value = rotate_pulse_fine
    current_note.volume_value = volume_value
    
    current_phrase:line(i + 1):note_column(1).note_value = 120 -- note off
  end    
end

function show_gui()
  if dialog and dialog.visible then
    dialog:show()
    return
  end

  vb = renoise.ViewBuilder()
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local TEXT_ROW_WIDTH = 80

  local track_row = vb:row {
    vb:column {
      vb:text {
        text = 'Polygon Shape',
        style = 'strong'
      },
      vb:popup {
        items = {
          '2-gon',
          '3-gon',
          '4-gon',
          '5-gon',
          '6-gon',
          '7-gon',
          '8-gon',
          '9-gon',
          '10-gon',
          '11-gon',
          '12-gon',
          '13-gon',
          '17-gon',
          '19-gon',
          '23-gon',
          '29-gon'
        },
        value = 1,
        width = 70,
        tooltip = 'Polygon Shape',
        bind = options.notes_count
      },
      vb:text {
        text = 'Beat shift',
        style = 'strong'
      },
      vb:slider {
        id = "pulse_rotation_slider",
        min = 0,
        max = options.current_pulse.value,
        steps = {1,1},        
        bind = options.rotate_pulse
      },
      vb:valuefield {
        id = "pulse_shift_input",
        min = 0,
        max = 3,        
        width = TEXT_ROW_WIDTH,
        bind = options.rotate_pulse,
        tonumber = function(value)          
          return math.floor(value)
        end,
        tostring = function(value)
          return string.format("%d", value)
        end
      },
      vb:slider {
        id = "pulse_subphase_rotation",
        steps = {1,1},
        min = 0,
        max = 255,
        bind = options.rotate_pulse_fine
      },
      vb:valuefield {
        id = "pulse_subphase_rotation_input",
        min = 0,
        max = 255,
        width = TEXT_ROW_WIDTH,
        bind = options.rotate_pulse_fine,
        tonumber = function(value)          
          return math.floor(value)
        end,
        tostring = function(value)
          return string.format("%d", value)
        end
      }
    }
  }

  local dialog_content = vb:column {
    margin = DEFAULT_MARGIN,
    vb:row {
      vb:valuebox {
        min = 1,
        max = 96,
        tooltip = 'Pulses per beat multiplier',
        bind = options.current_pulse
      },
      vb:text {        
        text = 'pulses',
        width = TEXT_ROW_WIDTH,        
      },
    },    
    vb:column {      
      style = "group",      
      margin = DEFAULT_MARGIN,      
      vb:text {
        text = "Track 1"
      },
      track_row
    }
  }
  dialog = renoise.app():show_custom_dialog('RePulse', dialog_content)
end

-- Tool setup
renoise.tool():add_menu_entry {
  name = "Phrase Editor:Pulse...",
  invoke = show_gui
}

function update_pulse_rotation_max_value()
  local current_pulse = math.floor(options.current_pulse.value)
  local rotation_max = renoise.song().transport.lpb
  vb.views.pulse_rotation_slider.max = current_pulse * rotation_max
end

function update_ui_and_calculate()
  calculate_pulse()
  update_pulse_rotation_max_value()
end

-- Do UI events binding...
options.current_pulse:add_notifier(update_ui_and_calculate)
options.rotate_pulse:add_notifier(calculate_pulse)
options.rotate_pulse_fine:add_notifier(calculate_pulse)
options.notes_count:add_notifier(calculate_pulse)

renoise.song().transport.lpb_observable:add_notifier(update_ui_and_calculate)
