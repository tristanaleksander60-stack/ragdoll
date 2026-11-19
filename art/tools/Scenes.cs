// The game's icon and thumbnails in the same hand-drawn sticker style as the icons (10 Nov 2026,
// the owner: like the top ragdoll games, which have the highest click rates): a big scared ragdoll
// flying, bright sun rays, a red wrecking ball, lava, explosions, chunky wobbly title letters.
// art\tools\build-art.ps1 draws them into art\store\.
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;

public static partial class Doodles
{
	static void Back(GraphicsPath p, Color c) { items.Add(new Layer { P = p, C = c, Shade = false, Shine = false, Edge = false, Inked = false }); }
	static void BackInk(GraphicsPath p, Color c) { items.Add(new Layer { P = p, C = c, Shade = false, Shine = false, Edge = false }); }

	// Sun rays from a point, two colours, over the whole canvas.
	static void Rays(float cx, float cy, int n, Color a, Color b)
	{
		Back(Rect(-50, -50, W + 100, H + 100), a);
		float far = (W + H) * 1.5f;
		for (int i = 0; i < n; i += 2)
		{
			double a0 = i * Math.PI * 2 / n, a1 = (i + 1) * Math.PI * 2 / n;
			var p = new GraphicsPath();
			p.AddPolygon(new PointF[] {
				new PointF(cx, cy),
				new PointF(cx + (float)Math.Cos(a0) * far, cy + (float)Math.Sin(a0) * far),
				new PointF(cx + (float)Math.Cos(a1) * far, cy + (float)Math.Sin(a1) * far) });
			Back(p, b);
		}
	}

	static GraphicsPath T(GraphicsPath p, float deg, float px, float py) { return Turn(p, deg, px, py); }

	// A blocky ragdoll (a crash-test dummy when dummy is true), centre of the torso at cx, cy, turned
	// by turn; arms and legs at their own angles (degrees, 0 = hanging down / standing).
	static void Figure(float cx, float cy, float s, float turn, float armL, float armR, float legL, float legR, Color skin, Color shirt, Color pants, bool dummy, bool scared)
	{
		Func<GraphicsPath, GraphicsPath> whole = p => T(p, turn, cx, cy);
		// Back arm and leg first.
		Add(whole(T(Rect(cx + 34 * s, cy - 36 * s, 26 * s, 70 * s), armR, cx + 47 * s, cy - 30 * s)), dummy ? skin : skin);
		Add(whole(T(Rect(cx + 2 * s, cy + 34 * s, 30 * s, 72 * s), legR, cx + 17 * s, cy + 38 * s)), pants);
		// Torso.
		Add(whole(Rect(cx - 34 * s, cy - 40 * s, 68 * s, 80 * s)), shirt);
		if (dummy)
		{
			// The crash-test mark: a black and yellow disc on the chest.
			Add(whole(Oval(cx, cy - 6 * s, 15 * s, 15 * s)), Yellow);
			Back(whole(Poly(cx, cy - 6 * s, cx + 15 * s, cy - 6 * s, cx + 14 * s, cy + 2 * s, cx + 8 * s, cy + 8 * s, cx, cy + 9 * s)), Black);
			Back(whole(Poly(cx, cy - 6 * s, cx - 15 * s, cy - 6 * s, cx - 14 * s, cy - 14 * s, cx - 8 * s, cy - 19 * s, cx, cy - 21 * s)), Black);
		}
		// Front leg and arm.
		Add(whole(T(Rect(cx - 32 * s, cy + 34 * s, 30 * s, 72 * s), legL, cx - 17 * s, cy + 38 * s)), pants);
		Add(whole(T(Rect(cx - 60 * s, cy - 36 * s, 26 * s, 70 * s), armL, cx - 47 * s, cy - 30 * s)), skin);
		// Head and face.
		Add(whole(Rect(cx - 30 * s, cy - 98 * s, 60 * s, 56 * s)), skin);
		if (scared)
		{
			Add(whole(Oval(cx - 12 * s, cy - 74 * s, 10 * s, 12 * s)), White);
			Add(whole(Oval(cx + 13 * s, cy - 74 * s, 10 * s, 12 * s)), White);
			Back(whole(Oval(cx - 11 * s, cy - 72 * s, 4 * s, 5 * s)), Black);
			Back(whole(Oval(cx + 14 * s, cy - 72 * s, 4 * s, 5 * s)), Black);
			BackInk(whole(Oval(cx + 1 * s, cy - 54 * s, 9 * s, 8 * s)), Rgb(150, 40, 50));
		}
	}

	static void Brows(float cx, float cy, float s, float turn)
	{
		var a = new PointF[] { new PointF(cx - 22 * s, cy - 92 * s), new PointF(cx - 4 * s, cy - 88 * s) };
		var b = new PointF[] { new PointF(cx + 4 * s, cy - 88 * s), new PointF(cx + 22 * s, cy - 92 * s) };
		var m = new Matrix();
		m.RotateAt(turn, new PointF(cx, cy));
		m.TransformPoints(a);
		m.TransformPoints(b);
		Ink(6 * K, a[0].X, a[0].Y, a[1].X, a[1].Y);
		Ink(6 * K, b[0].X, b[0].Y, b[1].X, b[1].Y);
	}

	static void WreckingBall(float x, float y, float r, float chainTopX, float chainTopY)
	{
		Line(Iron, 10 * K, chainTopX, chainTopY, (chainTopX + x) / 2, (chainTopY + y) / 2 - 10, x, y - r);
		Add(Oval(x, y, r, r), Red);
	}

	static void Boom(float x, float y, float r, string word, float tilt)
	{
		items.Add(new Layer { P = Star(x, y, r, r * 0.62f, 11, tilt), C = Orange, InkW = Math.Min(7 * K, r * 0.05f) });
		items.Add(new Layer { P = Star(x, y, r * 0.66f, r * 0.42f, 9, tilt + 15), C = Yellow, InkW = Math.Min(5 * K, r * 0.035f), Edge = false });
		if (word != null) Title(word, x, y + r * 0.04f, r * 0.42f, Red, tilt * 0.3f, 0);
	}

	static void Lava(float x, float y, float w, float h)
	{
		BackInk(Poly(x, y + h * 0.2f, x + w * 0.2f, y, x + w * 0.5f, y + h * 0.1f, x + w * 0.8f, y, x + w, y + h * 0.2f, x + w, y + h, x, y + h), Orange);
		for (int i = 0; i < 6; i++)
		{
			float bx = x + w * (0.1f + i * 0.15f);
			Back(Oval(bx, y + h * (0.35f + (i % 2) * 0.25f), w * 0.04f, h * 0.08f), Yellow);
		}
		// Flames.
		for (int i = 0; i < 4; i++)
		{
			float fx = x + w * (0.15f + i * 0.22f);
			Add(Poly(fx - 22 * K, y + 10, fx - 6 * K, y - 18 * K, fx, y - 34 * K - (i % 2) * 12 * K, fx + 8 * K, y - 16 * K, fx + 22 * K, y + 10), Rgb(255, 170, 40));
		}
	}

	static void Spikes(float x, float y, float w, int n, float h)
	{
		Add(Rect(x, y, w, h * 0.7f), Red);
		float step = w / n;
		for (int i = 0; i < n; i++)
			Add(Poly(x + i * step + step * 0.1f, y + 2, x + i * step + step * 0.5f, y - h, x + i * step + step * 0.9f, y + 2), Rgb(220, 224, 234));
	}

	static void Target(float x, float y, float r)
	{
		Add(Oval(x, y, r, r * 0.42f), White);
		Back(Oval(x, y, r * 0.75f, r * 0.31f), Red);
		Back(Oval(x, y, r * 0.5f, r * 0.21f), White);
		Back(Oval(x, y, r * 0.25f, r * 0.1f), Red);
	}

	// Chunky title letters, each a little turned and bobbing, like a hand-lettered sign.
	static void Title(string text, float cx, float cy, float size, Color c, float tilt, float bob)
	{
		Func<char, float> adv = ch => (ch == 'L' || ch == 'I' || ch == '!' ? 0.6f : ch == ' ' ? 0.42f : ch == 'M' || ch == 'W' ? 0.92f : 0.78f) * size;
		float width = 0;
		foreach (char ch in text) width += adv(ch);
		float run = cx - width / 2;
		for (int i = 0; i < text.Length; i++)
		{
			float x = run + adv(text[i]) / 2;
			run += adv(text[i]);
			if (text[i] == ' ') continue;
			float y = cy + (float)Math.Sin(i * 1.3) * bob + x * (float)Math.Tan(tilt * Math.PI / 180) - cx * (float)Math.Tan(tilt * Math.PI / 180);
			float r = tilt + (float)(rng.NextDouble() * 2 - 1) * 6;
			items.Add(new Label { T = text[i].ToString(), X = x, Y = y, Size = size, R = r, C = Color.White, Ink = Color.White, InkW = size * 0.42f });
			items.Add(new Label { T = text[i].ToString(), X = x, Y = y, Size = size, R = r, C = c, InkW = size * 0.2f });
		}
	}

	static void Cloud2(float cx, float cy, float s)
	{
		Cloud(cx, cy, s, White);
	}

	public static void Scene(string name)
	{
		rng = new Random(name.GetHashCode());
		jit = 2.2f * K;
		switch (name)
		{
			case "icon":
			{
				// A big scared dummy flung through the air, the red ball just hit him, a BOOM behind.
				Rays(250, 260, 20, Rgb(70, 170, 255), Rgb(120, 200, 255));
				Boom(150, 150, 120, null, 10);
				WreckingBall(430, 140, 70, 430, -20);
				Motion(330, 330, 120, 40, 3);
				Figure(250, 300, 2.2f, -24, 150, -150, 40, -35, Yellow, Yellow, Rgb(40, 40, 52), true, true);
				Brows(250, 300, 2.2f, -24);
				Add(Star(420, 300, 40, 18, 4, 0), Yellow);
				Add(Star(90, 420, 30, 13, 4, 0), Yellow);
				break;
			}
			case "thumb_fling":
			{
				Rays(1300, 400, 26, Rgb(70, 170, 255), Rgb(115, 196, 255));
				Cloud2(260, 180, 2.2f); Cloud2(1650, 900, 2.6f);
				WreckingBall(1500, 330, 150, 1400, -40);
				Boom(1260, 420, 150, "BONK!", -8);
				Figure(850, 520, 4.0f, -35, 160, -140, 50, -30, Skin, Blue, Rgb(60, 70, 120), false, true);
				Brows(850, 520, 4.0f, -35);
				Motion(1020, 700, 260, 70, 3);
				Figure(300, 760, 1.8f, 60, 120, -90, 20, -50, Yellow, Yellow, Rgb(40, 40, 52), true, true);
				Figure(1650, 650, 1.5f, -110, 100, -160, 70, -10, Yellow, Yellow, Rgb(40, 40, 52), true, true);
				Title("RAGDOLL HAVOC", 700, 150, 112, Yellow, -5, 10);
				break;
			}
			case "thumb_lava":
			{
				Rays(960, 1200, 24, Rgb(255, 170, 70), Rgb(255, 200, 110));
				Lava(0, 840, 1920, 260);
				Spikes(60, 760, 420, 5, 110);
				Spikes(1500, 760, 360, 4, 110);
				Target(1580, 700, 170);
				// The human cannon, lower left, and the dummy it just fired.
				Add(T(Rect(80, 560, 330, 120), -30, 245, 620), Rgb(60, 62, 78));
				Add(Oval(250, 690, 70, 70), Wood);
				Boom(420, 470, 110, "BOOM!", 10);
				Motion(600, 520, 240, 60, 3);
				Figure(1040, 500, 2.5f, 30, 160, -160, 60, -60, Yellow, Yellow, Rgb(40, 40, 52), true, true);
				Brows(1040, 500, 2.5f, 30);
				Title("RAGDOLL HAVOC", 960, 130, 120, Yellow, 0, 12);
				break;
			}
			case "thumb_tnt":
			{
				Rays(1100, 560, 26, Rgb(150, 90, 230), Rgb(185, 130, 255));
				Boom(1100, 600, 330, "KABOOM!", -6);
				Figure(560, 470, 3.0f, -50, 170, -120, 70, -20, Skin, Red, Rgb(40, 50, 90), false, true);
				Brows(560, 470, 3.0f, -50);
				Figure(1600, 330, 2.4f, 70, 130, -170, 40, -60, Yellow, Yellow, Rgb(40, 40, 52), true, true);
				Figure(1450, 880, 2.0f, 150, 100, -100, 30, -40, Yellow, Yellow, Rgb(40, 40, 52), true, true);
				Title("RAGDOLL HAVOC", 700, 140, 112, Yellow, -6, 10);
				break;
			}
			// Badges (512 x 512; Roblox shows them in a circle, so everything stays inside r ~ 220).
			case "badge_welcome":
			{
				// A dummy waving hello with both arms, a big HI! sign.
				Rays(256, 256, 18, Rgb(70, 170, 255), Rgb(120, 200, 255));
				Add(Star(120, 150, 30, 13, 4, 0), Yellow);
				Add(Star(400, 380, 24, 10, 4, 0), Yellow);
				Figure(256, 320, 1.6f, 0, 160, -160, 8, -8, Yellow, Yellow, Rgb(40, 40, 52), true, false);
				// A happy face: eyes and a smile.
				Back(Oval(244, 194, 5, 6), Black);
				Back(Oval(268, 194, 5, 6), Black);
				Ink(5 * K, 240, 212, 256, 220, 272, 212);
				Title("HI!", 256, 92, 92, Yellow, -4, 4);
				break;
			}
			case "badge_first_takedown":
			{
				// The first knockout: a dummy flung back by a boxing glove, BONK!
				Rays(256, 256, 18, Rgb(240, 80, 70), Rgb(255, 130, 110));
				Boom(150, 170, 92, "BONK!", -10);
				Motion(170, 330, 110, 34, 3);
				Figure(320, 300, 1.45f, 55, 150, -130, 50, -40, Yellow, Yellow, Rgb(40, 40, 52), true, true);
				Brows(320, 300, 1.45f, 55);
				Add(Star(410, 140, 26, 11, 4, 0), Yellow);
				break;
			}
			case "badge_first_egg":
			{
				// A cracked weapon egg, a rocket bursting out of it, sparkles.
				Rays(256, 256, 18, Rgb(150, 90, 230), Rgb(190, 140, 255));
				// The rocket, behind the shell.
				Add(T(Rect(236, 70, 40, 130), 18, 256, 135), Steel);
				Add(T(Poly(236, 72, 256, 30, 276, 72), 18, 256, 135), Red);
				// The lower shell with a zigzag top.
				Add(Poly(140, 250, 175, 228, 205, 262, 240, 226, 272, 262, 305, 226, 338, 260, 372, 250,
					380, 320, 350, 400, 300, 440, 256, 448, 212, 440, 162, 400, 132, 320), Rgb(255, 236, 200));
				// Spots on the shell.
				Back(Oval(205, 340, 22, 16), Pink);
				Back(Oval(300, 380, 18, 13), Cyan);
				Back(Oval(320, 300, 14, 10), Yellow);
				// The top half flying off.
				Add(T(Poly(150, 200, 180, 150, 230, 120, 280, 118, 320, 140, 345, 190, 315, 176, 285, 205, 255, 172, 222, 206, 190, 176), -28, 250, 160), Rgb(255, 236, 200));
				Add(Star(120, 210, 26, 11, 4, 0), Yellow);
				Add(Star(400, 230, 32, 14, 4, 10), Yellow);
				Add(Star(390, 110, 18, 8, 4, 0), White);
				break;
			}
			case "badge_five_minutes":
			{
				// A chunky alarm clock at 5 minutes past, ringing.
				Rays(256, 256, 18, Rgb(80, 190, 90), Rgb(130, 220, 120));
				Add(Oval(170, 130, 40, 34), Red);
				Add(Oval(342, 130, 40, 34), Red);
				Add(Oval(256, 270, 160, 160), Red);
				Add(Oval(256, 270, 128, 128), White);
				for (int i = 0; i < 12; i++)
				{
					double a = i * Math.PI / 6;
					float r0 = i % 3 == 0 ? 96 : 108, r1 = 118;
					Ink((i % 3 == 0 ? 7 : 4) * K, 256 + (float)Math.Sin(a) * r0, 270 - (float)Math.Cos(a) * r0, 256 + (float)Math.Sin(a) * r1, 270 - (float)Math.Cos(a) * r1);
				}
				Line(Black, 10 * K, 256, 270, 256, 196);
				Line(Red, 8 * K, 256, 270, 256 + (float)Math.Sin(Math.PI / 6) * 96, 270 - (float)Math.Cos(Math.PI / 6) * 96);
				Add(Oval(256, 270, 12, 12), Black);
				Motion(70, 220, 50, 26, 3);
				Motion(400, 220, 50, 26, 3);
				Title("5 MIN", 256, 460, 64, Yellow, 0, 4);
				break;
			}
			case "badge_bullseye":
			{
				// A dummy dropping onto the middle of a big target.
				Rays(256, 256, 18, Rgb(255, 160, 50), Rgb(255, 200, 100));
				Target(256, 360, 210);
				Motion(140, 120, 90, 30, 3);
				Figure(270, 220, 1.35f, 160, 140, -140, 30, -30, Yellow, Yellow, Rgb(40, 40, 52), true, true);
				Add(Star(400, 120, 30, 13, 4, 0), Yellow);
				Add(Star(110, 280, 22, 9, 4, 0), White);
				break;
			}
			default:
				throw new Exception("no scene " + name);
		}
	}

	public static int BuildArt(string dir)
	{
		return BuildList(dir, new string[][] {
			new string[] { "icon", "512", "512", "2" },
			new string[] { "thumb_fling", "1920", "1080", "3.5" },
			new string[] { "thumb_lava", "1920", "1080", "3.5" },
			new string[] { "thumb_tnt", "1920", "1080", "3.5" },
		});
	}

	public static int BuildBadges(string dir)
	{
		return BuildList(dir, new string[][] {
			new string[] { "badge_welcome", "512", "512", "2" },
			new string[] { "badge_first_takedown", "512", "512", "2" },
			new string[] { "badge_first_egg", "512", "512", "2" },
			new string[] { "badge_five_minutes", "512", "512", "2" },
			new string[] { "badge_bullseye", "512", "512", "2" },
		});
	}

	static int BuildList(string dir, string[][] list)
	{
		foreach (var e in list)
		{
			W = int.Parse(e[1]); H = int.Parse(e[2]); K = float.Parse(e[3], System.Globalization.CultureInfo.InvariantCulture);
			Scene(e[0]);
			Render(System.IO.Path.Combine(dir, e[0] + ".png"));
		}
		W = 256; H = 256; K = 1; jit = 2.2f;
		return list.Length;
	}
}
