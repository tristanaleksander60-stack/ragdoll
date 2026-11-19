--!strict
-- Uploaded image assets. Sources live in art/ (faces drawn by tools/make_faces.py).
-- To re-upload: render, copy art/faces to the PC, serve the folder on localhost and pass the URLs
-- to the Studio upload tool (it only accepts http URLs).

return table.freeze({
	Faces = table.freeze({
		Neutral = "rbxassetid://118036776168698",
		Blink = "rbxassetid://105356191562052",
		Ouch = "rbxassetid://104706203982986",
		Dizzy = "rbxassetid://116714927219944",
		Scared = "rbxassetid://117187404699134",
		Grumpy = "rbxassetid://119712894206796",
	}),
	Star = "rbxassetid://138586015540643",
	Recenter = "rbxassetid://74920012383888",
	Broom = "rbxassetid://76870017362943",
})
