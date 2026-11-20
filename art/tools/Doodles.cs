// Hand-drawn style icons for Ragdoll Havoc (10 Nov 2026, the owner: "much less AI-like, as if drawn").
// Every icon is a sticker doodle: flat cartoon colours, a cel shade on the lower right, a small white
// highlight, a thick black ink line with a slight hand wobble, and a white sticker edge round it all.
// Built with System.Drawing (no Python here): art\tools\build-icons.ps1 compiles and runs this and
// writes art\icons\<name>.png (256 px).
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static partial class Doodles
{
	const int S = 256;
	public static int W = 256, H = 256;
	public static float K = 1; // (line widths: 1 for an icon, more for big pictures)
	static Random rng = new Random(7);
	static float jit = 2.2f;
	static List<object> items = new List<object>();

	class Layer { public GraphicsPath P; public Color C; public bool Shade = true; public bool Shine = true; public bool Edge = true; public bool Inked = true; public float InkW = -1; }
	class Stroke { public PointF[] Pts; public Color C; public float W; public bool Ink = true; }
	class Label { public string T; public float X, Y, Size, R; public Color C; public Color Ink = Color.FromArgb(255, 30, 30, 36); public float InkW = -1; }

	static float J() { return (float)(rng.NextDouble() * 2 - 1) * jit; }

	static PointF[] Sub(PointF[] pts, bool closed, float seg)
	{
		var outPts = new List<PointF>();
		int n = pts.Length;
		int edges = closed ? n : n - 1;
		for (int i = 0; i < edges; i++)
		{
			PointF a = pts[i], b = pts[(i + 1) % n];
			float len = (float)Math.Sqrt((b.X - a.X) * (b.X - a.X) + (b.Y - a.Y) * (b.Y - a.Y));
			int k = Math.Max(1, (int)(len / (seg * K)));
			for (int s = 0; s < k; s++)
			{
				float t = s / (float)k;
				outPts.Add(new PointF(a.X + (b.X - a.X) * t + J(), a.Y + (b.Y - a.Y) * t + J()));
			}
		}
		if (!closed) outPts.Add(new PointF(pts[n - 1].X + J(), pts[n - 1].Y + J()));
		return outPts.ToArray();
	}

	static PointF[] Pts(float[] xy)
	{
		var p = new PointF[xy.Length / 2];
		for (int i = 0; i < p.Length; i++) p[i] = new PointF(xy[i * 2], xy[i * 2 + 1]);
		return p;
	}

	// A wobbly closed polygon (its corners softened like a marker's).
	public static GraphicsPath Poly(params float[] xy)
	{
		var path = new GraphicsPath();
		path.AddClosedCurve(Sub(Pts(xy), true, 22), 0.25f);
		return path;
	}

	public static GraphicsPath Rect(float x, float y, float w, float h)
	{
		return Poly(x, y, x + w, y, x + w, y + h, x, y + h);
	}

	public static GraphicsPath Oval(float cx, float cy, float rx, float ry)
	{
		int n = 28;
		var p = new PointF[n];
		for (int i = 0; i < n; i++)
		{
			double a = i * Math.PI * 2 / n;
			float wob = 1 + J() * 0.008f / K;
			p[i] = new PointF(cx + (float)Math.Cos(a) * rx * wob, cy + (float)Math.Sin(a) * ry * wob);
		}
		var path = new GraphicsPath();
		path.AddClosedCurve(p, 0.5f);
		return path;
	}

	public static GraphicsPath Star(float cx, float cy, float r1, float r2, int points, float turn)
	{
		var xy = new List<float>();
		for (int i = 0; i < points * 2; i++)
		{
			double a = (i * Math.PI / points) - Math.PI / 2 + turn * Math.PI / 180;
			float r = (i % 2 == 0) ? r1 : r2;
			xy.Add(cx + (float)Math.Cos(a) * r);
			xy.Add(cy + (float)Math.Sin(a) * r);
		}
		var path = new GraphicsPath();
		path.AddClosedCurve(Sub(Pts(xy.ToArray()), true, 400), 0.12f);
		return path;
	}

	public static GraphicsPath Turn(GraphicsPath p, float deg, float cx, float cy)
	{
		var m = new Matrix();
		m.RotateAt(deg, new PointF(cx, cy));
		p.Transform(m);
		return p;
	}

	static Color Rgb(int r, int g, int b) { return Color.FromArgb(255, r, g, b); }
	static Color Dark(Color c, float k) { return Color.FromArgb(255, (int)(c.R * k), (int)(c.G * k), (int)(c.B * k)); }

	static void Add(GraphicsPath p, Color c) { items.Add(new Layer { P = p, C = c }); }
	static void Flat(GraphicsPath p, Color c) { items.Add(new Layer { P = p, C = c, Shade = false, Shine = false }); }
	static void Line(Color c, float w, params float[] xy) { items.Add(new Stroke { Pts = Sub(Pts(xy), false, 30), C = c, W = w }); }
	static void Ink(float w, params float[] xy) { items.Add(new Stroke { Pts = Sub(Pts(xy), false, 30), C = Color.Black, W = w, Ink = false }); }
	static void Text(string t, float x, float y, float size, Color c) { items.Add(new Label { T = t, X = x, Y = y, Size = size, C = c }); }

	static readonly Color Black = Rgb(30, 30, 36);
	static readonly Color White = Rgb(250, 250, 252);
	static readonly Color Skin = Rgb(255, 206, 160);
	static readonly Color Steel = Rgb(170, 178, 194);
	static readonly Color Iron = Rgb(88, 92, 106);
	static readonly Color Wood = Rgb(198, 138, 78);
	static readonly Color Red = Rgb(236, 64, 56);
	static readonly Color Yellow = Rgb(255, 206, 54);
	static readonly Color Orange = Rgb(255, 140, 40);
	static readonly Color Blue = Rgb(70, 160, 255);
	static readonly Color Cyan = Rgb(120, 220, 255);
	static readonly Color Pink = Rgb(255, 110, 190);
	static readonly Color Purple = Rgb(150, 90, 230);
	static readonly Color Green = Rgb(100, 214, 90);

	public static void Render(string file)
	{
		using (var bmp = new Bitmap(W, H, PixelFormat.Format32bppArgb))
		using (var g = Graphics.FromImage(bmp))
		{
			g.SmoothingMode = SmoothingMode.AntiAlias;
			g.PixelOffsetMode = PixelOffsetMode.HighQuality;
			g.Clear(Color.Transparent);
			// The white sticker edge round everything.
			using (var edge = new Pen(Color.White, 30 * K) { LineJoin = LineJoin.Round, StartCap = LineCap.Round, EndCap = LineCap.Round })
			using (var white = new SolidBrush(Color.White))
			{
				foreach (var it in items)
				{
					var l = it as Layer;
					if (l != null) { if (l.Edge) { var bb = l.P.GetBounds(); using (var e2 = new Pen(Color.White, Math.Min(30 * K, Math.Max(8, Math.Min(bb.Width, bb.Height) * 0.4f))) { LineJoin = LineJoin.Round }) { g.FillPath(white, l.P); g.DrawPath(e2, l.P); } } continue; }
					var s = it as Stroke;
					if (s != null)
					{
						using (var pen = new Pen(Color.White, s.W + 30 * K) { LineJoin = LineJoin.Round, StartCap = LineCap.Round, EndCap = LineCap.Round })
							g.DrawCurve(pen, s.Pts, 0.4f);
					}
				}
			}
			foreach (var it in items)
			{
				var l = it as Layer;
				if (l != null)
				{
					using (var b = new SolidBrush(l.C)) g.FillPath(b, l.P);
					RectangleF box = l.P.GetBounds();
					if (l.Shade)
					{
						// Cel shade: the colour darkened, then the colour again shifted up-left.
						var keep = g.Clip;
						g.SetClip(l.P);
						using (var d = new SolidBrush(Dark(l.C, 0.74f))) g.FillPath(d, l.P);
						using (var lit = (GraphicsPath)l.P.Clone())
						using (var b = new SolidBrush(l.C))
						{
							var m = new Matrix();
							float off = Math.Max(4, Math.Min(10, Math.Min(box.Width, box.Height) * 0.09f));
							m.Translate(-off, -off);
							lit.Transform(m);
							g.FillPath(b, lit);
						}
						g.Clip = keep;
					}
					if (l.Shine && box.Width > 46 && box.Height > 46)
					{
						// A short white highlight, upper left.
						using (var pen = new Pen(Color.FromArgb(230, 255, 255, 255), Math.Max(5, Math.Min(box.Width, box.Height) * 0.07f)) { StartCap = LineCap.Round, EndCap = LineCap.Round })
						{
							float rx = box.Width * 0.30f, ry = box.Height * 0.30f;
							float cx = box.X + box.Width / 2, cy = box.Y + box.Height / 2;
							var arc = new PointF[4];
							for (int i = 0; i < 4; i++)
							{
								double a = (200 + i * 14) * Math.PI / 180;
								arc[i] = new PointF(cx + (float)Math.Cos(a) * rx, cy + (float)Math.Sin(a) * ry);
							}
							var keep = g.Clip;
							g.SetClip(l.P);
							g.DrawCurve(pen, arc, 0.5f);
							g.Clip = keep;
						}
					}
					if (l.Inked) using (var ink = new Pen(Black, l.InkW > 0 ? l.InkW : Math.Min(11 * K, Math.Max(3, Math.Min(box.Width, box.Height) * 0.13f))) { LineJoin = LineJoin.Round }) g.DrawPath(ink, l.P);
					continue;
				}
				var s = it as Stroke;
				if (s != null)
				{
					if (s.Ink)
					{
						using (var pen = new Pen(Black, s.W + 11 * K) { LineJoin = LineJoin.Round, StartCap = LineCap.Round, EndCap = LineCap.Round })
							g.DrawCurve(pen, s.Pts, 0.4f);
					}
					using (var pen = new Pen(s.Ink ? s.C : Black, s.W) { LineJoin = LineJoin.Round, StartCap = LineCap.Round, EndCap = LineCap.Round })
						g.DrawCurve(pen, s.Pts, 0.4f);
					continue;
				}
				var t = it as Label;
				if (t != null)
				{
					using (var f = new Font("Arial Black", t.Size, FontStyle.Bold, GraphicsUnit.Pixel))
					using (var path = new GraphicsPath())
					{
						var fmt = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center };
						path.AddString(t.T, f.FontFamily, (int)FontStyle.Bold, t.Size, new PointF(0, 0), fmt);
						var place = new Matrix();
						place.Translate(t.X, t.Y);
						place.Rotate(t.R);
						path.Transform(place);
						using (var ink = new Pen(t.Ink, t.InkW > 0 ? t.InkW : 9 * K * t.Size / 60f + 6) { LineJoin = LineJoin.Round }) g.DrawPath(ink, path);
						using (var b = new SolidBrush(t.C)) g.FillPath(b, path);
					}
				}
			}
			if (W == S && H == S)
			{
				// An icon: what was drawn, centred and filling the square the same way every time
				// (a doodle drawn off to one side would sit off-centre in every tile).
				int minX = S, minY = S, maxX = -1, maxY = -1;
				for (int y = 0; y < S; y++)
					for (int x = 0; x < S; x++)
						if (bmp.GetPixel(x, y).A > 12)
						{
							if (x < minX) minX = x; if (x > maxX) maxX = x;
							if (y < minY) minY = y; if (y > maxY) maxY = y;
						}
				if (maxX > minX && maxY > minY)
				{
					int w = maxX - minX + 1, h = maxY - minY + 1;
					float scale = 240f / Math.Max(w, h);
					using (var outBmp = new Bitmap(S, S, PixelFormat.Format32bppArgb))
					using (var og = Graphics.FromImage(outBmp))
					{
						og.Clear(Color.Transparent);
						og.InterpolationMode = InterpolationMode.HighQualityBicubic;
						og.PixelOffsetMode = PixelOffsetMode.HighQuality;
						float dw = w * scale, dh = h * scale;
						og.DrawImage(bmp, new RectangleF((S - dw) / 2, (S - dh) / 2, dw, dh), new RectangleF(minX, minY, w, h), GraphicsUnit.Pixel);
						outBmp.Save(file, ImageFormat.Png);
					}
					items.Clear();
					return;
				}
			}
			bmp.Save(file, ImageFormat.Png);
		}
		items.Clear();
	}

	// ---- shared bits -------------------------------------------------------------------------
	static void Hand(float cx, float cy, float s, float turn, Color c)
	{
		// An open hand: palm, four fingers, a thumb (palm up the picture).
		// Fingers first (the palm's line crosses their roots, as a drawn hand's does).
		for (int i = 0; i < 4; i++)
		{
			float fx = cx - 27 * s + i * 18 * s;
			float ry = (i == 1 || i == 2) ? 34 * s : 29 * s;
			float fy = cy - 30 * s + (i == 0 || i == 3 ? 6 * s : 0);
			Add(Turn(Turn(Oval(fx, fy, 10.5f * s, ry), (i - 1.5f) * 7, fx, cy), turn, cx, cy), c);
		}
		Add(Turn(Turn(Oval(cx - 40 * s, cy + 10 * s, 13 * s, 28 * s), -38, cx - 40 * s, cy + 10 * s), turn, cx, cy), c); // thumb
		Add(Turn(Poly(cx - 38 * s, cy - 8 * s, cx + 38 * s, cy - 8 * s, cx + 36 * s, cy + 44 * s, cx, cy + 58 * s, cx - 34 * s, cy + 44 * s), turn, cx, cy), c);
	}

	static void Fist(float cx, float cy, float s, Color c)
	{
		Add(Poly(cx - 56 * s, cy - 34 * s, cx + 44 * s, cy - 40 * s, cx + 58 * s, cy + 10 * s, cx + 40 * s, cy + 50 * s, cx - 50 * s, cy + 48 * s), c);
		for (int i = 0; i < 3; i++) Ink(6, cx - 20 * s + i * 24 * s, cy - 36 * s, cx - 22 * s + i * 24 * s, cy - 6 * s);
		Add(Oval(cx - 48 * s, cy + 8 * s, 22 * s, 16 * s), c); // thumb
	}

	static void BoxingGlove(float cx, float cy, float s, Color c, float turn)
	{
		// A mitt (rounded), its thumb on the side, a white cuff under it.
		Add(Turn(Rect(cx - 36 * s, cy + 54 * s, 72 * s, 44 * s), turn, cx, cy), White);
		Add(Turn(Poly(cx - 56 * s, cy + 10 * s, cx - 44 * s, cy - 54 * s, cx + 10 * s, cy - 76 * s, cx + 58 * s, cy - 44 * s, cx + 60 * s, cy + 30 * s, cx + 36 * s, cy + 60 * s, cx - 40 * s, cy + 60 * s), turn, cx, cy), c);
		Add(Turn(Turn(Oval(cx - 52 * s, cy + 20 * s, 18 * s, 30 * s), -20, cx - 52 * s, cy + 20 * s), turn, cx, cy), c);
	}

	static void Motion(float x, float y, float len, float gap, int n)
	{
		for (int i = 0; i < n; i++) Ink(7 * K, x, y + i * gap, x + len - i * 10 * K, y + i * gap);
	}

	static void Spark(float cx, float cy, float r)
	{
		Add(Star(cx, cy, r, r * 0.45f, 8, 10), Yellow);
		Flat(Star(cx, cy, r * 0.5f, r * 0.22f, 8, 30), Orange);
	}

	static void Cloud(float cx, float cy, float s, Color c)
	{
		// One outline with bumps (a drawn cloud is one line, not overlapping circles).
		float[] xy = { -72, 36, -86, 12, -70, -12, -44, -18, -34, -46, 0, -60, 32, -50, 46, -24, 72, -20, 88, 6, 74, 36 };
		var pts = new PointF[xy.Length / 2];
		for (int i = 0; i < pts.Length; i++) pts[i] = new PointF(cx + xy[i * 2] * s + J(), cy + xy[i * 2 + 1] * s + J());
		var p = new GraphicsPath();
		p.AddClosedCurve(pts, 0.55f);
		Add(p, c);
	}

	static void Dummy(float cx, float cy, float s, float turn)
	{
		// A tiny crash-test dummy: yellow head and body, black limbs.
		var body = Turn(Rect(cx - 10 * s, cy - 2 * s, 20 * s, 26 * s), turn, cx, cy);
		var head = Turn(Oval(cx, cy - 16 * s, 12 * s, 12 * s), turn, cx, cy);
		Add(body, Yellow);
		Add(head, Yellow);
	}

	// ---- the icons --------------------------------------------------------------------------
	public static void Draw(string name)
	{
		rng = new Random(name.GetHashCode());
		switch (name)
		{
			// UI
			case "shop":
				Ink(14, 24, 58, 52, 60, 76, 168, 200, 168);
				Add(Poly(56, 74, 222, 74, 200, 152, 76, 152), Yellow);
				for (int i = 0; i < 3; i++) Ink(6, 104 + i * 36, 80, 102 + i * 34, 146);
				Add(Oval(96, 200, 18, 18), Iron); Add(Oval(184, 200, 18, 18), Iron);
				break;
			case "settings":
			{
				var xy = new List<float>();
				for (int i = 0; i < 32; i++)
				{
					double a = i * Math.PI * 2 / 32;
					float r = (i % 4 == 0 || i % 4 == 1) ? 104 : 80;
					xy.Add(128 + (float)Math.Cos(a) * r); xy.Add(128 + (float)Math.Sin(a) * r);
				}
				Add(Poly(xy.ToArray()), Steel);
				Add(Oval(128, 128, 34, 34), Iron);
				break;
			}
			case "sandbox":
				Add(Rect(44, 52, 168, 160), Wood);
				Ink(7, 44, 104, 212, 106); Ink(7, 44, 158, 212, 158);
				Line(Dark(Wood, 0.8f), 12, 56, 66, 200, 200);
				Line(Dark(Wood, 0.8f), 12, 200, 66, 56, 200);
				break;
			case "gift":
				Add(Oval(128, 140, 74, 92), Rgb(255, 244, 222));
				Flat(Oval(102, 112, 16, 16), Orange); Flat(Oval(156, 150, 13, 13), Orange); Flat(Oval(112, 186, 10, 10), Orange);
				break;
			// (21 Nov 2026, the owner: "no big text, signs and icons a child understands": the lab's
			// pictogram set. World signs and the HUD use the same pictures.)
			case "sign_lava":
				Add(Poly(128, 22, 238, 222, 18, 222), Red);
				Flat(Poly(128, 54, 210, 204, 46, 204), White);
				Add(Poly(128, 84, 162, 150, 150, 192, 106, 192, 94, 150), Orange);
				Flat(Poly(128, 128, 144, 160, 136, 186, 120, 186, 112, 160), Yellow);
				break;
			case "sign_target":
				Add(Oval(128, 128, 104, 104), Red); Add(Oval(128, 128, 76, 76), White);
				Add(Oval(128, 128, 48, 48), Red); Add(Oval(128, 128, 20, 20), White);
				break;
			case "sign_up":
				Add(Poly(128, 18, 214, 118, 164, 118, 164, 238, 92, 238, 92, 118, 42, 118), Blue);
				break;
			case "sign_fling":
				Line(Purple, 30, 40, 200, 70, 110, 140, 70, 196, 84);
				Add(Poly(176, 40, 240, 92, 168, 130), Purple);
				break;
			case "sign_crash":
				Add(Rect(176, 30, 52, 196), Iron);
				Ink(5, 176, 80, 228, 80); Ink(5, 176, 130, 228, 130); Ink(5, 176, 180, 228, 180);
				Add(Poly(28, 104, 140, 104, 140, 82, 176, 128, 140, 174, 140, 152, 28, 152), Red);
				break;
			case "sign_wrecking":
				Ink(10, 128, 18, 128, 112);
				Add(Rect(84, 12, 88, 16), Iron);
				Add(Oval(128, 162, 66, 66), Red);
				Flat(Oval(104, 138, 16, 12), Rgb(255, 150, 150));
				break;
			case "sign_bounce":
				Add(Rect(36, 176, 184, 22), Blue);
				Ink(10, 52, 196, 40, 232); Ink(10, 204, 196, 216, 232);
				Add(Poly(128, 30, 176, 92, 148, 92, 148, 150, 108, 150, 108, 92, 80, 92), Green);
				break;
			case "sign_button":
				Add(Rect(40, 150, 176, 56), Steel);
				Add(Oval(128, 140, 70, 34), Rgb(170, 30, 30));
				Add(Oval(128, 124, 70, 34), Red);
				break;
			case "sign_tower":
				Add(Rect(60, 40, 70, 196), Rgb(206, 208, 212));
				Add(Rect(60, 40, 70, 20), Yellow);
				Add(Poly(164, 60, 226, 60, 226, 150, 250, 150, 195, 220, 140, 150, 164, 150), Orange);
				break;
			case "sign_car":
				Add(Poly(36, 150, 60, 96, 190, 96, 222, 150), Red);
				Add(Rect(24, 146, 208, 44), Red);
				Flat(Poly(78, 104, 124, 104, 124, 144, 66, 144), Cyan); Flat(Poly(136, 104, 182, 104, 204, 144, 136, 144), Cyan);
				Add(Oval(74, 192, 24, 24), Black); Add(Oval(182, 192, 24, 24), Black);
				break;
			case "sign_monster":
				Add(Oval(128, 140, 90, 76), Purple);
				Add(Oval(96, 116, 22, 26), White); Add(Oval(160, 116, 22, 26), White);
				Flat(Oval(100, 122, 9, 11), Black); Flat(Oval(156, 122, 9, 11), Black);
				Add(Poly(80, 166, 176, 166, 160, 196, 96, 196), Black);
				Flat(Poly(96, 166, 108, 166, 102, 180), White); Flat(Poly(148, 166, 160, 166, 154, 180), White);
				break;
			case "hud_click":
				Add(Oval(128, 140, 66, 96), White);
				Flat(Poly(128, 44, 128, 128, 62, 128, 70, 80, 96, 52), Orange);
				Ink(6, 128, 44, 128, 128); Ink(6, 62, 128, 194, 128);
				break;
			case "hud_tap":
				Add(Oval(150, 70, 30, 30), Rgb(255, 230, 120));
				Add(Poly(116, 92, 140, 92, 140, 150, 196, 150, 204, 236, 112, 236, 92, 176, 116, 176), Skin);
				break;
			case "hud_ragdoll":
				Add(Oval(150, 58, 30, 30), White);
				Add(Turn(Rect(96, 86, 52, 84), -28, 122, 128), White);
				Add(Turn(Rect(36, 82, 70, 22), 20, 70, 92), White); Add(Turn(Rect(160, 116, 70, 22), 40, 196, 126), White);
				Add(Turn(Rect(70, 170, 22, 66), 30, 82, 200), White); Add(Turn(Rect(128, 172, 22, 66), -20, 140, 204), White);
				break;
			case "hud_slowmo":
				Add(Oval(128, 132, 96, 96), Cyan);
				Add(Oval(128, 132, 76, 76), White);
				Ink(10, 128, 132, 128, 78); Ink(10, 128, 132, 166, 150);
				Add(Rect(108, 24, 40, 16), Iron);
				break;
			case "guide_feed":
				// (21 Nov 2026: the lab's guide signs: a crash-test dummy and a big arrow, "put one in".)
				Add(Rect(34, 156, 20, 52), White); Add(Rect(62, 156, 20, 52), White);
				Add(Rect(30, 100, 56, 62), White);
				Add(Turn(Rect(8, 104, 18, 46), 18, 17, 104), White); Add(Turn(Rect(90, 104, 18, 46), -18, 99, 104), White);
				Add(Oval(58, 70, 28, 28), White);
				Flat(Poly(58, 70, 58, 46, 76, 52, 82, 70), Yellow); Flat(Poly(58, 70, 58, 94, 40, 88, 34, 70), Yellow);
				Flat(Poly(58, 70, 82, 70, 76, 88, 58, 94), Black); Flat(Poly(58, 70, 34, 70, 40, 52, 58, 46), Black);
				Line(Orange, 22, 118, 132, 150, 100, 188, 106);
				Add(Poly(176, 76, 232, 118, 172, 146), Orange);
				break;
			case "present":
				// (UI audit 21 Nov 2026: REWARDS is a present, not an egg; the play gift pays BOLTS.)
				Add(Turn(Oval(98, 66, 34, 20), 28, 98, 66), Yellow);
				Add(Turn(Oval(158, 66, 34, 20), -28, 158, 66), Yellow);
				Add(Rect(48, 112, 160, 104), Red);
				Add(Rect(36, 82, 184, 38), Dark(Red, 0.85f));
				Add(Rect(114, 82, 28, 134), Yellow);
				Add(Oval(128, 80, 16, 13), Yellow);
				break;
			case "star":
				Add(Star(128, 136, 108, 46, 5, 0), Yellow);
				break;
			case "crown":
				Add(Poly(36, 196, 36, 76, 84, 132, 128, 56, 172, 132, 220, 76, 220, 196), Yellow);
				Add(Oval(84, 170, 14, 14), Red); Add(Oval(128, 170, 14, 14), Blue); Add(Oval(172, 170, 14, 14), Green);
				break;
			case "toolbox":
				Ink(14, 92, 92, 96, 56, 160, 56, 164, 92);
				Add(Rect(32, 90, 192, 118), Red);
				Add(Rect(110, 128, 36, 26), Steel);
				break;
			case "map":
				Add(Poly(30, 60, 98, 40, 158, 60, 226, 40, 226, 200, 158, 220, 98, 200, 30, 220), Rgb(150, 220, 120));
				Ink(6, 98, 42, 98, 200); Ink(6, 158, 60, 158, 218);
				Line(Red, 8, 52, 186, 90, 140, 130, 160, 176, 102);
				Text("X", 192, 92, 54, Red);
				break;
			case "friends":
				Add(Oval(92, 112, 58, 58), Yellow); Add(Oval(170, 140, 58, 58), Blue);
				Flat(Oval(76, 104, 7, 9), Black); Flat(Oval(106, 104, 7, 9), Black); Ink(6, 74, 132, 92, 142, 112, 132);
				Flat(Oval(154, 132, 7, 9), Black); Flat(Oval(184, 132, 7, 9), Black); Ink(6, 152, 160, 170, 170, 190, 160);
				break;
			case "camera":
				Add(Oval(84, 70, 34, 34), Iron); Add(Oval(150, 70, 34, 34), Iron);
				Add(Rect(40, 104, 140, 96), Rgb(70, 74, 90));
				Add(Poly(180, 130, 228, 104, 228, 200, 180, 176), Iron);
				Flat(Oval(66, 128, 10, 10), Red);
				break;
			case "music":
				Ink(12, 108, 186, 108, 64, 200, 46, 200, 166);
				Add(Turn(Oval(88, 192, 28, 20), -20, 88, 192), Purple);
				Add(Turn(Oval(180, 172, 28, 20), -20, 180, 172), Purple);
				break;
			case "keys":
				Add(Rect(48, 48, 160, 160), Rgb(236, 238, 244));
				Text("W", 128, 124, 96, Black);
				break;
			case "eye":
				Add(Poly(24, 128, 70, 76, 128, 62, 186, 76, 232, 128, 186, 180, 128, 194, 70, 180), White);
				Add(Oval(128, 128, 46, 46), Blue);
				Flat(Oval(128, 128, 20, 20), Black);
				Flat(Oval(116, 114, 8, 8), White);
				break;
			case "shake":
				Add(Rect(84, 40, 88, 176), Iron);
				Flat(Rect(96, 58, 64, 128), Cyan);
				Ink(8, 54, 84, 40, 128, 54, 172); Ink(8, 202, 84, 216, 128, 202, 172);
				break;
			case "heart":
				Add(Poly(128, 220, 40, 136, 34, 86, 60, 52, 100, 48, 128, 78, 156, 48, 196, 52, 222, 86, 216, 136), Red);
				Line(White, 8, 52, 132, 96, 132, 112, 100, 132, 166, 150, 120, 204, 120);
				break;
			// Events
			case "event_DummyRain":
				Cloud(128, 84, 1.1f, Rgb(200, 220, 240));
				Dummy(70, 186, 1.6f, -20); Dummy(130, 206, 1.6f, 15); Dummy(190, 180, 1.6f, -35);
				break;
			case "event_MegaBomb":
				Add(Oval(116, 150, 84, 84), Rgb(54, 56, 70));
				Add(Turn(Rect(150, 62, 36, 30), 40, 168, 77), Iron);
				Line(Wood, 8, 182, 66, 200, 44, 218, 46);
				Spark(222, 40, 26);
				break;
			case "event_ZeroG":
				Add(Oval(128, 128, 68, 68), Purple);
				Line(Orange, 12, 26, 160, 80, 186, 160, 170, 226, 118);
				Add(Star(52, 58, 22, 9, 4, 0), Yellow); Add(Star(208, 210, 16, 7, 4, 0), Yellow);
				break;
			case "event_BouncyFloor":
				Add(Rect(40, 52, 176, 34), Pink);
				Line(Steel, 12, 128, 92, 82, 112, 174, 134, 82, 156, 174, 178, 128, 196);
				Add(Rect(40, 196, 176, 26), Iron);
				break;
			case "event_FlashFreeze":
				Add(Turn(Rect(56, 56, 144, 144), 10, 128, 128), Cyan);
				Line(White, 10, 128, 82, 128, 174); Line(White, 10, 88, 106, 168, 150); Line(White, 10, 168, 106, 88, 150);
				break;
			// Weapons (tool_<id>)
			case "tool_Blaster":
				Add(Turn(Poly(36, 82, 204, 82, 212, 122, 36, 124), -8, 128, 128), Iron);
				Add(Turn(Poly(128, 118, 184, 118, 202, 214, 146, 216), -8, 128, 128), Black);
				Ink(9, 112, 128, 104, 166, 136, 168);
				break;
			case "tool_Deagle":
				Add(Turn(Poly(24, 80, 222, 76, 226, 128, 24, 132), -10, 128, 128), Rgb(196, 182, 140));
				Add(Turn(Poly(134, 124, 190, 124, 210, 222, 152, 224), -10, 128, 128), Wood);
				Ink(9, 112, 136, 104, 172, 140, 174);
				break;
			case "tool_Shotgun":
				Add(Turn(Rect(80, 108, 166, 22), -32, 128, 128), Iron);
				Add(Turn(Rect(96, 132, 70, 20), -32, 128, 128), Wood);
				Add(Turn(Poly(10, 120, 86, 110, 92, 146, 20, 168), -32, 128, 128), Wood);
				break;
			case "tool_NailGun":
				Add(Poly(40, 70, 196, 70, 206, 120, 40, 120), Yellow);
				Add(Poly(120, 116, 168, 116, 176, 210, 130, 210), Iron);
				Add(Rect(196, 82, 28, 26), Steel);
				Ink(7, 52, 136, 52, 196); Ink(7, 72, 136, 72, 196); Ink(7, 92, 136, 92, 196);
				break;
			case "tool_Crossbow":
				Line(Wood, 14, 30, 120, 128, 52, 226, 120);
				Ink(5, 30, 120, 226, 120);
				Add(Rect(116, 100, 24, 130), Wood);
				Add(Poly(128, 18, 112, 52, 144, 52), Steel);
				Ink(6, 128, 52, 128, 120);
				break;
			case "tool_Portal":
				Add(Poly(34, 96, 168, 84, 176, 134, 34, 142), Rgb(230, 232, 240));
				Add(Poly(80, 136, 124, 136, 132, 210, 90, 210), Iron);
				Add(Oval(196, 106, 34, 34), Pink);
				Flat(Oval(196, 106, 16, 16), Cyan);
				break;
			case "tool_Slime":
				Add(Poly(40, 160, 66, 86, 128, 60, 190, 84, 214, 160, 190, 206, 66, 208), Green);
				Add(Oval(70, 220, 12, 18), Green); Add(Oval(180, 224, 10, 16), Green);
				Flat(Oval(100, 120, 12, 14), Black); Flat(Oval(150, 120, 12, 14), Black);
				break;
			case "tool_Grab":
				Hand(128, 140, 1.25f, 0, Rgb(140, 230, 150));
				break;
			case "tool_Poke":
				Fist(118, 152, 1.0f, Skin);
				Add(Turn(Oval(148, 70, 15, 46), 20, 148, 70), Skin);
				break;
			case "tool_Slap":
				Hand(140, 138, 1.15f, -20, Skin);
				Motion(16, 90, 60, 30, 3);
				break;
			case "tool_Shove":
				Hand(146, 130, 1.1f, 80, Rgb(255, 176, 90));
				Motion(14, 92, 64, 34, 3);
				break;
			case "tool_Punch":
				Fist(140, 134, 1.3f, Rgb(255, 150, 100));
				Motion(14, 96, 50, 34, 3);
				break;
			case "tool_Kick":
				Add(Poly(70, 26, 130, 26, 130, 150, 214, 168, 220, 214, 70, 214), Rgb(255, 120, 120));
				Add(Rect(64, 196, 162, 26), Iron);
				break;
			case "tool_Uppercut":
				BoxingGlove(110, 120, 1.0f, Rgb(255, 90, 140), 0);
				Line(Yellow, 12, 220, 206, 220, 70); Line(Yellow, 12, 198, 96, 220, 62, 242, 96);
				break;
			case "tool_MegaSlap":
				Hand(128, 138, 1.45f, 0, Rgb(255, 80, 200));
				break;
			case "tool_Glove":
				Line(Steel, 10, 18, 214, 42, 186, 62, 222, 82, 186, 102, 214);
				BoxingGlove(156, 112, 0.95f, Red, -60);
				break;
			case "tool_Pan":
				Add(Turn(Rect(150, 116, 96, 26), 30, 150, 128), Iron);
				Add(Oval(96, 112, 76, 76), Rgb(70, 74, 88));
				Flat(Oval(96, 112, 56, 56), Rgb(110, 114, 130));
				break;
			case "tool_Bat":
				Add(Turn(Poly(14, 116, 160, 100, 246, 106, 246, 150, 160, 150, 14, 136), -38, 128, 128), Wood);
				break;
			case "tool_Golf":
				Line(Steel, 10, 196, 24, 96, 198);
				Add(Poly(56, 186, 104, 184, 112, 214, 50, 214), Iron);
				Add(Oval(170, 210, 20, 20), White);
				break;
			case "tool_Hammer":
				Add(Turn(Rect(118, 90, 24, 150), 30, 128, 128), Wood);
				Add(Turn(Rect(46, 28, 150, 76), 30, 128, 128), Rgb(176, 112, 70));
				break;
			case "tool_Crowbar":
				Line(Red, 16, 196, 222, 72, 56, 54, 40, 34, 52, 40, 72);
				break;
			case "tool_Axe":
				Add(Turn(Rect(120, 40, 22, 196), 25, 128, 128), Wood);
				Add(Turn(Poly(130, 40, 210, 26, 228, 96, 210, 140, 132, 108), 25, 128, 128), Steel);
				break;
			case "tool_Cleaver":
				Add(Turn(Poly(60, 50, 200, 50, 206, 150, 60, 150), -20, 128, 128), Steel);
				Add(Turn(Rect(80, 150, 30, 84), -20, 128, 128), Black);
				Flat(Turn(Oval(176, 76, 10, 10), -20, 128, 128), Black);
				break;
			case "tool_Katana":
				Add(Turn(Poly(20, 126, 160, 112, 246, 96, 160, 132, 20, 140), -36, 128, 128), Rgb(226, 230, 240));
				Add(Turn(Rect(10, 118, 58, 30), -36, 128, 128), Rgb(60, 50, 90));
				Add(Turn(Oval(72, 134, 10, 26), -36, 128, 128), Yellow);
				break;
			case "tool_Chainsaw":
				Add(Poly(20, 96, 120, 96, 130, 196, 20, 196), Orange);
				Add(Rect(118, 120, 124, 44), Steel);
				for (int i = 0; i < 6; i++) Ink(5, 128 + i * 20, 116, 136 + i * 20, 106);
				Ink(10, 40, 96, 60, 60, 100, 60, 112, 96);
				break;
			case "tool_PlasmaBlade":
				Add(Turn(Rect(118, 18, 24, 170), 30, 128, 128), Cyan);
				Flat(Turn(Rect(124, 30, 10, 150), 30, 128, 128), White);
				Add(Turn(Rect(112, 186, 34, 60), 30, 128, 128), Iron);
				break;
			case "tool_Launch":
				Add(Poly(40, 200, 150, 90, 120, 70, 214, 42, 190, 136, 170, 110, 62, 222), Red);
				Motion(20, 120, 60, 30, 2);
				break;
			case "tool_Firecracker":
				Add(Turn(Rect(80, 80, 70, 150), 20, 128, 150), Red);
				Add(Turn(Rect(80, 120, 70, 20), 20, 128, 150), Yellow);
				Line(Wood, 7, 150, 74, 164, 46, 186, 40);
				Spark(196, 36, 24);
				break;
			case "tool_TNT":
				Add(Rect(46, 76, 52, 150), Red); Add(Rect(102, 70, 52, 156), Red); Add(Rect(158, 76, 52, 150), Red);
				Add(Rect(40, 136, 176, 30), Wood);
				Text("TNT", 128, 151, 30, White);
				Line(Wood, 7, 128, 70, 140, 40, 166, 30);
				Spark(178, 28, 22);
				break;
			case "tool_Shockwave":
				Line(Cyan, 12, 30, 128, 60, 60, 128, 32, 196, 60, 226, 128, 196, 196, 128, 224, 60, 196, 30, 128);
				Line(Blue, 12, 70, 128, 86, 88, 128, 72, 170, 88, 186, 128, 170, 168, 128, 184, 86, 168, 70, 128);
				Add(Oval(128, 128, 18, 18), White);
				break;
			case "tool_StickyBomb":
				Add(Poly(40, 150, 60, 80, 128, 52, 196, 80, 216, 150, 186, 210, 70, 210), Rgb(110, 220, 100));
				Add(Oval(128, 126, 30, 30), Iron);
				Flat(Oval(128, 126, 14, 14), Red);
				Add(Oval(60, 220, 10, 14), Rgb(110, 220, 100));
				break;
			case "tool_Cannon":
				Add(Turn(Poly(40, 90, 210, 80, 220, 140, 40, 150), -20, 128, 128), Rgb(60, 62, 78));
				Add(Oval(100, 176, 46, 46), Wood);
				Flat(Oval(100, 176, 14, 14), Iron);
				break;
			case "tool_BigBoom":
				Add(Star(128, 128, 116, 64, 11, 8), Orange);
				Add(Star(128, 128, 68, 36, 9, 20), Yellow);
				Text("BOOM", 128, 130, 40, Red);
				break;
			case "tool_Rocket":
				Add(Turn(Poly(128, 18, 160, 70, 160, 180, 96, 180, 96, 70), 40, 128, 128), White);
				Add(Turn(Poly(128, 18, 156, 64, 100, 64), 40, 128, 128), Red);
				Add(Turn(Poly(96, 140, 66, 196, 96, 180), 40, 128, 128), Red);
				Add(Turn(Poly(160, 140, 190, 196, 160, 180), 40, 128, 128), Red);
				Add(Turn(Oval(128, 104, 16, 16), 40, 128, 128), Blue);
				Add(Turn(Poly(104, 184, 152, 184, 128, 240), 40, 128, 128), Orange);
				break;
			case "tool_Balloon":
				Line(Black, 4, 128, 186, 118, 216, 134, 244);
				Add(Oval(128, 104, 70, 84), Pink);
				Add(Poly(118, 184, 138, 184, 128, 198), Pink);
				break;
			case "tool_Freeze":
				Line(Cyan, 12, 128, 28, 128, 228); Line(Cyan, 12, 42, 78, 214, 178); Line(Cyan, 12, 214, 78, 42, 178);
				Line(Cyan, 9, 106, 46, 128, 64, 150, 46); Line(Cyan, 9, 106, 210, 128, 192, 150, 210);
				Add(Oval(128, 128, 20, 20), White);
				break;
			case "tool_Zap":
				Add(Poly(146, 18, 56, 140, 118, 140, 92, 238, 204, 100, 138, 100), Yellow);
				break;
			case "tool_BlackHole":
				Add(Oval(128, 128, 104, 104), Purple);
				Line(Pink, 9, 128, 40, 196, 76, 210, 140, 170, 196, 110, 200, 72, 160, 80, 110, 120, 88, 160, 112);
				Flat(Oval(128, 128, 34, 34), Black);
				break;
			case "tool_Heal":
				Add(Turn(Rect(20, 92, 216, 72), -35, 128, 128), Rgb(245, 214, 170));
				Add(Turn(Rect(98, 98, 60, 60), -35, 128, 128), White);
				Text("+", 128, 128, 64, Rgb(80, 210, 140));
				break;
			case "tool_Anvil":
				Add(Poly(20, 76, 196, 76, 236, 92, 196, 120, 160, 128, 172, 176, 210, 214, 46, 214, 84, 176, 96, 128, 56, 118), Iron);
				break;
			case "tool_Trampoline":
				Ink(12, 64, 150, 48, 214); Ink(12, 192, 150, 208, 214); Ink(12, 128, 160, 128, 220);
				Add(Oval(128, 132, 108, 36), Blue);
				Flat(Oval(128, 128, 84, 22), Rgb(40, 60, 110));
				break;
			case "tool_SpringPad":
				Add(Rect(56, 60, 144, 36), Pink);
				Line(Steel, 12, 128, 100, 84, 120, 172, 142, 84, 164, 172, 186, 128, 204);
				Add(Rect(48, 200, 160, 24), Iron);
				break;
			case "tool_Banana":
				Add(Poly(40, 70, 64, 150, 120, 200, 196, 210, 232, 186, 186, 170, 126, 150, 82, 106, 70, 56), Yellow);
				Add(Rect(56, 34, 18, 28), Wood);
				break;
			case "tool_Fan":
				Add(Oval(128, 116, 96, 96), Rgb(170, 220, 255));
				Add(Turn(Oval(128, 76, 22, 38), 0, 128, 116), White);
				Add(Turn(Oval(128, 76, 22, 38), 120, 128, 116), White);
				Add(Turn(Oval(128, 76, 22, 38), 240, 128, 116), White);
				Add(Oval(128, 116, 14, 14), Iron);
				Add(Rect(96, 206, 64, 24), Iron);
				break;
			case "tool_Bowling":
				Add(Poly(176, 30, 196, 40, 192, 80, 214, 140, 204, 226, 152, 226, 142, 140, 162, 80, 158, 40), White);
				Flat(Rect(158, 76, 38, 12), Red);
				Add(Oval(96, 150, 72, 72), Purple);
				Flat(Oval(80, 126, 9, 9), Black); Flat(Oval(106, 120, 9, 9), Black); Flat(Oval(92, 148, 9, 9), Black);
				break;
			case "tool_Shrink":
				Line(Rgb(120, 70, 40), 12, 40, 220, 160, 96);
				Add(Star(176, 78, 50, 22, 5, 10), Rgb(200, 130, 255));
				Add(Star(76, 76, 18, 8, 4, 0), Yellow); Add(Star(220, 170, 14, 6, 4, 0), Yellow);
				break;
			case "tool_Chicken":
				Add(Poly(52, 120, 96, 70, 150, 60, 190, 80, 214, 140, 196, 200, 110, 214, 54, 180), Rgb(255, 246, 220));
				Add(Poly(150, 54, 160, 26, 176, 46, 190, 30, 192, 66), Red);
				Add(Poly(206, 96, 240, 108, 206, 122), Orange);
				Flat(Oval(182, 92, 7, 8), Black);
				Ink(8, 120, 214, 116, 240); Ink(8, 156, 212, 160, 240);
				break;
			case "tool_Float":
				Cloud(128, 168, 1.0f, Rgb(200, 226, 250));
				Line(Blue, 12, 128, 112, 128, 26); Line(Blue, 12, 104, 54, 128, 26, 152, 54);
				break;
			case "tool_Slowmo":
				Add(Rect(56, 22, 144, 24), Wood); Add(Rect(56, 210, 144, 24), Wood);
				Add(Poly(70, 46, 186, 46, 140, 128, 186, 210, 70, 210, 116, 128), Rgb(214, 236, 255));
				Flat(Poly(94, 192, 162, 192, 128, 150), Yellow);
				Flat(Poly(100, 66, 156, 66, 128, 104), Yellow);
				break;
			case "tool_Grenade":
				Add(Oval(128, 150, 70, 76), Rgb(96, 116, 70));
				Ink(6, 70, 130, 186, 130); Ink(6, 64, 170, 192, 170); Ink(6, 128, 78, 128, 222);
				Add(Rect(108, 54, 40, 30), Steel);
				Line(Steel, 10, 150, 60, 190, 40, 196, 96);
				Add(Oval(98, 48, 16, 16), Yellow);
				break;
			case "tool_C4":
				Add(Rect(40, 90, 176, 110), Rgb(220, 206, 160));
				Add(Rect(84, 66, 88, 44), Iron);
				Flat(Rect(94, 74, 68, 26), Rgb(90, 220, 110));
				Text("0:03", 128, 87, 22, Black);
				Line(Red, 8, 50, 120, 30, 70, 70, 50);
				Line(Blue, 8, 206, 120, 226, 70, 186, 50);
				break;
			case "tool_Minigun":
				Add(Rect(24, 92, 96, 70), Iron);
				Add(Rect(110, 90, 130, 18), Steel); Add(Rect(110, 112, 130, 18), Steel); Add(Rect(110, 134, 130, 18), Steel);
				Add(Rect(40, 158, 34, 60), Black);
				Add(Rect(60, 60, 50, 36), Rgb(96, 116, 70));
				break;
			case "tool_Sniper":
				Add(Turn(Rect(10, 120, 236, 14), -18, 128, 128), Iron);
				Add(Turn(Poly(20, 116, 104, 112, 112, 150, 30, 168), -18, 128, 128), Rgb(96, 116, 70));
				Add(Turn(Rect(96, 86, 80, 22), -18, 128, 128), Black);
				Add(Turn(Oval(180, 97, 9, 12), -18, 128, 128), Cyan);
				break;
			case "tool_RPG":
				Add(Turn(Rect(18, 104, 190, 40), -25, 128, 128), Rgb(96, 116, 70));
				Add(Turn(Poly(200, 96, 246, 124, 200, 152), -25, 128, 128), Rgb(120, 130, 90));
				Add(Turn(Rect(96, 144, 26, 44), -25, 128, 128), Iron);
				Spark(36, 186, 26);
				break;
			case "tool_GravityGun":
				Add(Rect(30, 100, 140, 60), Orange);
				Add(Rect(60, 156, 34, 56), Iron);
				Line(Iron, 10, 166, 104, 220, 70); Line(Iron, 10, 166, 156, 220, 190); Line(Iron, 10, 170, 130, 232, 130);
				Add(Oval(196, 130, 22, 22), Yellow);
				break;
			case "tool_Nuke":
				Add(Poly(128, 18, 176, 70, 176, 190, 80, 190, 80, 70), Yellow);
				Add(Poly(80, 170, 46, 230, 80, 214), Iron); Add(Poly(176, 170, 210, 230, 176, 214), Iron);
				Add(Oval(128, 120, 32, 32), Black);
				Flat(Poly(128, 120, 116, 96, 140, 96), Yellow); Flat(Poly(128, 120, 104, 132, 116, 146), Yellow); Flat(Poly(128, 120, 152, 132, 140, 146), Yellow);
				break;
			// The gun ladder (10 Nov 2026): side views, muzzle to the right.
			case "tool_Revolver":
				// Cowboy six-shooter: a curved wooden grip, a big silver drum with its chambers, a long
				// silver barrel and a cocked hammer (never mistaken for the black, square G17).
				Add(Poly(30, 128, 78, 118, 96, 150, 82, 222, 44, 228, 34, 196), Wood);
				Add(Rect(70, 96, 52, 42), Steel);
				Add(Oval(116, 116, 36, 32), Rgb(214, 220, 232));
				Flat(Oval(104, 104, 7, 7), Iron); Flat(Oval(128, 104, 7, 7), Iron); Flat(Oval(104, 128, 7, 7), Iron); Flat(Oval(128, 128, 7, 7), Iron);
				Add(Rect(148, 100, 98, 22), Rgb(214, 220, 232));
				Add(Rect(236, 88, 8, 14), Black);
				Add(Poly(66, 98, 52, 70, 64, 66, 82, 96), Iron);
				Ink(6, 92, 140, 104, 158, 126, 142);
				break;
			case "tool_FlareGun":
				Add(Poly(50, 120, 92, 116, 104, 206, 64, 212), Orange);
				Add(Rect(70, 88, 70, 44), Orange);
				Add(Rect(130, 84, 100, 48), Rgb(255, 160, 70));
				Add(Rect(222, 80, 14, 56), Iron);
				Spark(244, 108, 18);
				break;
			case "tool_GoldenDeagle":
				Add(Poly(52, 124, 96, 120, 108, 210, 66, 216), Yellow);
				Add(Rect(60, 76, 176, 50), Rgb(255, 214, 90));
				Add(Rect(70, 120, 120, 22), Yellow);
				Flat(Rect(120, 84, 60, 10), Rgb(180, 130, 30));
				Add(Star(200, 60, 18, 8, 4, 0), White);
				break;
			case "tool_SMG":
				// A stubby blue machine pistol with a very long magazine and a wire stock.
				Add(Rect(70, 84, 130, 50), Rgb(70, 110, 170));
				Add(Rect(196, 100, 40, 16), Steel);
				Add(Poly(100, 130, 130, 130, 138, 246, 106, 248), Black);
				Line(Steel, 8, 70, 96, 20, 96, 20, 126, 70, 126);
				Flat(Rect(84, 94, 60, 8), Rgb(140, 180, 230));
				break;
			case "tool_AK":
				// Wood and black, and the curved banana magazine.
				Add(Poly(10, 112, 70, 102, 76, 140, 16, 172), Wood);
				Add(Rect(70, 96, 78, 34), Iron);
				Add(Rect(146, 100, 52, 26), Wood);
				Add(Rect(196, 106, 52, 10), Black);
				Add(Rect(222, 92, 6, 16), Black);
				Add(Poly(112, 128, 136, 128, 156, 168, 176, 210, 150, 222, 128, 176), Rgb(200, 120, 50));
				Add(Poly(80, 128, 98, 128, 96, 172, 78, 170), Wood);
				break;
			case "tool_M4":
				Add(Poly(14, 104, 60, 104, 62, 142, 14, 150), Black);
				Add(Rect(60, 94, 90, 36), Rgb(70, 72, 66));
				Add(Rect(148, 98, 60, 30), Iron);
				Add(Rect(206, 106, 40, 10), Black);
				Add(Rect(96, 74, 34, 22), Black); Flat(Oval(112, 85, 5, 5), Red);
				Add(Poly(112, 128, 132, 128, 140, 190, 118, 192), Black);
				Add(Poly(70, 128, 88, 128, 84, 166, 66, 164), Black);
				break;
			case "tool_TommyGun":
				Add(Poly(10, 104, 64, 100, 66, 136, 14, 154), Wood);
				Add(Rect(64, 92, 80, 32), Iron);
				Add(Rect(140, 98, 96, 18), Steel);
				Add(Oval(116, 150, 34, 34), Black);
				Add(Poly(170, 112, 186, 112, 182, 160, 166, 160), Wood);
				Add(Poly(72, 120, 90, 120, 86, 160, 68, 158), Wood);
				break;
			case "tool_AutoShotgun":
				// A chunky black combat shotgun with a row of red shells on its side.
				Add(Poly(10, 104, 64, 100, 66, 140, 14, 152), Iron);
				Add(Rect(62, 82, 100, 54), Black);
				for (int i = 0; i < 4; i++) Add(Rect(70 + i * 22, 92, 14, 32), Red);
				Add(Rect(160, 88, 84, 26), Steel);
				Add(Rect(160, 118, 66, 14), Iron);
				Add(Poly(80, 134, 100, 134, 112, 196, 86, 198), Black);
				break;
			case "tool_LMG":
				Add(Poly(6, 100, 56, 100, 58, 138, 8, 146), Black);
				Add(Rect(54, 86, 100, 46), Rgb(96, 116, 60));
				Add(Rect(150, 94, 60, 30), Rgb(96, 116, 60));
				Add(Rect(206, 104, 44, 10), Black);
				Add(Rect(92, 130, 46, 44), Rgb(110, 120, 90));
				Line(Yellow, 8, 114, 130, 120, 100);
				Ink(6, 196, 126, 180, 196); Ink(6, 204, 126, 224, 196);
				break;
			case "tool_DMR":
				Add(Poly(10, 104, 62, 100, 64, 140, 14, 154), Rgb(200, 176, 130));
				Add(Rect(60, 98, 140, 30), Rgb(200, 176, 130));
				Add(Rect(196, 106, 52, 10), Black);
				Add(Rect(80, 66, 90, 22), Black); Add(Oval(170, 77, 10, 13), Cyan);
				Add(Poly(112, 126, 130, 126, 132, 164, 112, 164), Black);
				break;
			case "tool_DoubleBarrel":
				Add(Poly(8, 110, 66, 100, 72, 140, 16, 170), Wood);
				Add(Rect(68, 98, 40, 36), Steel);
				Add(Rect(106, 96, 140, 14), Iron);
				Add(Rect(106, 112, 140, 14), Iron);
				Add(Rect(116, 124, 70, 16), Wood);
				break;
			case "tool_LaserRifle":
				Add(Poly(14, 104, 64, 100, 66, 140, 18, 150), White);
				Add(Rect(62, 86, 120, 50), White);
				Flat(Rect(72, 106, 100, 8), Red);
				Add(Rect(178, 100, 50, 22), Iron);
				Add(Oval(236, 111, 12, 12), Red);
				Add(Rect(100, 134, 30, 30), Red);
				break;
			case "tool_Railgun":
				Add(Poly(10, 104, 60, 98, 62, 140, 14, 150), Iron);
				Add(Rect(58, 88, 90, 52), Rgb(50, 56, 70));
				Add(Rect(146, 86, 104, 12), Steel);
				Add(Rect(146, 128, 104, 12), Steel);
				for (int i = 0; i < 3; i++) Add(Rect(160 + i * 28, 96, 10, 34), Cyan);
				Add(Rect(84, 138, 34, 30), Cyan);
				break;
			default:
				throw new Exception("no doodle for " + name);
		}
	}

	public static string[] Names = {
		"shop", "settings", "sandbox", "gift", "present", "guide_feed", "sign_lava", "sign_target", "sign_up", "sign_fling", "sign_crash", "sign_wrecking", "sign_bounce", "sign_button", "sign_tower", "sign_car", "sign_monster", "hud_click", "hud_tap", "hud_ragdoll", "hud_slowmo", "star", "crown", "toolbox", "map", "friends", "camera", "music", "keys", "eye", "shake", "heart",
		"event_DummyRain", "event_MegaBomb", "event_ZeroG", "event_BouncyFloor", "event_FlashFreeze",
		"tool_Blaster", "tool_Deagle", "tool_Shotgun", "tool_NailGun", "tool_Crossbow", "tool_Portal", "tool_Slime",
		"tool_Grab", "tool_Poke", "tool_Slap", "tool_Shove", "tool_Punch", "tool_Kick", "tool_Uppercut", "tool_MegaSlap", "tool_Glove",
		"tool_Pan", "tool_Bat", "tool_Golf", "tool_Hammer", "tool_Crowbar", "tool_Axe", "tool_Cleaver", "tool_Katana", "tool_Chainsaw", "tool_PlasmaBlade",
		"tool_Launch", "tool_Firecracker", "tool_TNT", "tool_Shockwave", "tool_StickyBomb", "tool_Cannon", "tool_BigBoom",
		"tool_Rocket", "tool_Balloon", "tool_Freeze", "tool_Zap", "tool_BlackHole", "tool_Heal", "tool_Anvil", "tool_Trampoline", "tool_SpringPad",
		"tool_Banana", "tool_Fan", "tool_Bowling", "tool_Shrink", "tool_Chicken", "tool_Float", "tool_Slowmo",
		"tool_Grenade", "tool_C4", "tool_Minigun", "tool_Sniper", "tool_RPG", "tool_GravityGun", "tool_Nuke",
		"tool_Revolver", "tool_FlareGun", "tool_GoldenDeagle", "tool_SMG", "tool_AK", "tool_M4", "tool_TommyGun",
		"tool_AutoShotgun", "tool_LMG", "tool_DMR", "tool_DoubleBarrel", "tool_LaserRifle", "tool_Railgun",
	};

	public static int Build(string dir, string only)
	{
		int n = 0;
		foreach (var name in Names)
		{
			if (!string.IsNullOrEmpty(only) && Array.IndexOf(only.Split(','), name) < 0) continue;
			Draw(name);
			Render(System.IO.Path.Combine(dir, name + ".png"));
			n++;
		}
		return n;
	}
}
