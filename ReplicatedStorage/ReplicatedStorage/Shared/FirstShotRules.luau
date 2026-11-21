--!strict
-- V9-0w: the pure rules of the first shot's glide into first person (Client/FirstShotFP, T175).

local FirstShotRules = {}

export type State = { lab: boolean, seated: boolean, building: boolean, director: boolean, window: boolean, guided: boolean, on: boolean }

-- Why not now (nil = now is fine): already in first person, the first visit's guided step, seated or
-- driving, the lab view, Build, Director mode, an open window.
function FirstShotRules.blockedBy(s: State): string?
	if s.on then
		return "on"
	elseif s.guided then
		return "guided"
	elseif s.seated then
		return "seated"
	elseif s.lab then
		return "lab"
	elseif s.building then
		return "building"
	elseif s.director then
		return "director"
	elseif s.window then
		return "window"
	end
	return nil
end

-- Whether to teach it on this shot: the switch on, the setting on, not taught before, a way back.
function FirstShotRules.shouldTeach(switch: boolean, fpShot: boolean, fpTaught: boolean, wayBack: boolean): boolean
	return switch and fpShot and not fpTaught and wayBack
end

-- The pill: how to go back, for this input.
function FirstShotRules.hintFor(pad: boolean, key: string): string
	return if pad then "First person! Select to switch back" else "First person! " .. key .. " to switch back"
end

return FirstShotRules
