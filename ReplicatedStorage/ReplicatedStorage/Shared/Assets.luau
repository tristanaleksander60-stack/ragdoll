--!strict
-- Uploaded image assets. Sources live in art/ (faces drawn by tools/make_faces.py).
-- To re-upload: render, copy art/faces to the PC, serve the folder on localhost and pass the URLs
-- to the Studio upload tool (it only accepts http URLs).

return table.freeze({
	Faces = table.freeze({
		Neutral = "rbxassetid://94304467307380",
		Blink = "rbxassetid://106424863891837",
		Ouch = "rbxassetid://93327759701699",
		Dizzy = "rbxassetid://116714927219944",
		Scared = "rbxassetid://93327759701699",
		Grumpy = "rbxassetid://93327759701699",
	}),
	Star = "rbxassetid://138586015540643",
	Recenter = "rbxassetid://74920012383888",
	Broom = "rbxassetid://76870017362943",
})
