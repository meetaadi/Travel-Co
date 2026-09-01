import { createClient } from "npm:@supabase/supabase-js@2.57.4";
import { Hono } from "npm:hono@4.6.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

type AuthUser = { id: string; email: string };

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function errorResponse(message: string, status = 400): Response {
  return json({ error: message }, status);
}

async function getUser(req: Request): Promise<AuthUser | null> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return null;

  const supabaseAnon = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!);
  const token = authHeader.replace("Bearer ", "");
  const { data } = await supabaseAnon.auth.getUser(token);
  return data.user as AuthUser | null;
}

function requireUser(user: AuthUser | null): AuthUser | Response {
  if (!user) return errorResponse("Authentication required", 401);
  return user;
}

const app = new Hono();

app.use("*", async (_c, next) => {
  await next();
});

app.options("*", (c) => {
  return new Response(null, { status: 200, headers: corsHeaders });
});

app.onError((err, _c) => {
  console.error("Unhandled error:", err);
  return errorResponse("Internal server error", 500);
});

// ─── TRIPS ───────────────────────────────────────────────────────────────────

app.get("/api/trips", async (c) => {
  try {
    const filter = c.req.query("type");
    let query = supabase
      .from("trips")
      .select(`
        id, title, type, duration_days, budget_text, travelers, blurb,
        cover_image, experiences, local_note, destination_id, user_id,
        destinations ( name, country ),
        profiles!inner ( display_name, handle ),
        trip_likes ( count ),
        trip_saves ( count )
      `)
      .eq("status", "published")
      .order("created_at", { ascending: false });

    if (filter && filter !== "For you") {
      query = query.eq("type", filter);
    }

    const { data, error } = await query;
    if (error) return errorResponse(error.message, 500);
    return json({ trips: data });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

app.get("/api/trips/:id", async (c) => {
  try {
    const tripId = c.req.param("id");
    const { data, error } = await supabase
      .from("trips")
      .select(`
        id, title, type, duration_days, budget_text, travelers, blurb,
        cover_image, experiences, local_note, destination_id, user_id,
        destinations ( name, country ),
        profiles!inner ( display_name, handle ),
        trip_likes ( count ),
        trip_saves ( count )
      `)
      .eq("id", tripId)
      .maybeSingle();

    if (error) return errorResponse(error.message, 500);
    if (!data) return errorResponse("Trip not found", 404);
    return json({ trip: data });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

app.post("/api/trips", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const body = await c.req.json();
    const { data, error } = await supabase
      .from("trips")
      .insert({
        user_id: user!.id,
        destination_id: body.destination_id,
        title: body.title,
        type: body.type,
        duration_days: body.duration_days,
        budget_text: body.budget_text,
        travelers: body.travelers ?? 1,
        blurb: body.blurb,
        cover_image: body.cover_image,
        experiences: body.experiences ?? [],
        local_note: body.local_note,
        status: body.status ?? "published",
      })
      .select("id")
      .single();

    if (error) return errorResponse(error.message, 500);
    return json({ trip: data }, 201);
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

// ─── DESTINATIONS ────────────────────────────────────────────────────────────

app.get("/api/destinations", async (_c) => {
  try {
    const { data, error } = await supabase
      .from("destinations")
      .select("id, name, country, slug, blurb, cover_image")
      .order("name");

    if (error) return errorResponse(error.message, 500);
    return json({ destinations: data });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

// ─── SOCIAL: LIKES ───────────────────────────────────────────────────────────

app.post("/api/trips/:id/like", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const tripId = c.req.param("id");
    const { error } = await supabase
      .from("trip_likes")
      .insert({ user_id: user!.id, trip_id: tripId });

    if (error) {
      if (error.code === "23505") return json({ liked: true });
      return errorResponse(error.message, 500);
    }
    return json({ liked: true });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

app.delete("/api/trips/:id/like", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const tripId = c.req.param("id");
    const { error } = await supabase
      .from("trip_likes")
      .delete()
      .eq("user_id", user!.id)
      .eq("trip_id", tripId);

    if (error) return errorResponse(error.message, 500);
    return json({ liked: false });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

// ─── SOCIAL: SAVES ───────────────────────────────────────────────────────────

app.post("/api/trips/:id/save", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const tripId = c.req.param("id");
    const { error } = await supabase
      .from("trip_saves")
      .insert({ user_id: user!.id, trip_id: tripId });

    if (error) {
      if (error.code === "23505") return json({ saved: true });
      return errorResponse(error.message, 500);
    }
    return json({ saved: true });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

app.delete("/api/trips/:id/save", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const tripId = c.req.param("id");
    const { error } = await supabase
      .from("trip_saves")
      .delete()
      .eq("user_id", user!.id)
      .eq("trip_id", tripId);

    if (error) return errorResponse(error.message, 500);
    return json({ saved: false });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

// ─── SOCIAL: FOLLOWS ─────────────────────────────────────────────────────────

app.post("/api/follows/:targetId", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const targetId = c.req.param("targetId");
    if (user!.id === targetId) return errorResponse("Cannot follow yourself", 400);

    const { error } = await supabase
      .from("user_follows")
      .insert({ follower_id: user!.id, following_id: targetId });

    if (error) {
      if (error.code === "23505") return json({ following: true });
      return errorResponse(error.message, 500);
    }
    return json({ following: true });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

app.delete("/api/follows/:targetId", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const targetId = c.req.param("targetId");
    const { error } = await supabase
      .from("user_follows")
      .delete()
      .eq("follower_id", user!.id)
      .eq("following_id", targetId);

    if (error) return errorResponse(error.message, 500);
    return json({ following: false });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

// ─── SOCIAL: USER STATE ──────────────────────────────────────────────────────

app.get("/api/social/me", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const [likesRes, savesRes, followsRes] = await Promise.all([
      supabase.from("trip_likes").select("trip_id").eq("user_id", user!.id),
      supabase.from("trip_saves").select("trip_id").eq("user_id", user!.id),
      supabase.from("user_follows").select("following_id").eq("follower_id", user!.id),
    ]);

    return json({
      likedTripIds: (likesRes.data ?? []).map((r: { trip_id: string }) => r.trip_id),
      savedTripIds: (savesRes.data ?? []).map((r: { trip_id: string }) => r.trip_id),
      followingIds: (followsRes.data ?? []).map((r: { following_id: string }) => r.following_id),
    });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

// ─── NOTIFICATIONS ───────────────────────────────────────────────────────────

app.get("/api/notifications", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const limit = parseInt(c.req.query("limit") ?? "20", 10);
    const { data, error } = await supabase
      .from("notifications")
      .select("id, type, message, read, created_at, actor_id")
      .eq("user_id", user!.id)
      .order("created_at", { ascending: false })
      .limit(limit);

    if (error) return errorResponse(error.message, 500);
    return json({ notifications: data });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

app.get("/api/notifications/unread-count", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const { count, error } = await supabase
      .from("notifications")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user!.id)
      .eq("read", false);

    if (error) return errorResponse(error.message, 500);
    return json({ unreadCount: count ?? 0 });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

app.put("/api/notifications/read-all", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const { error } = await supabase
      .from("notifications")
      .update({ read: true })
      .eq("user_id", user!.id)
      .eq("read", false);

    if (error) return errorResponse(error.message, 500);
    return json({ success: true });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

// ─── JOURNEYS ────────────────────────────────────────────────────────────────

app.post("/api/trips/:id/join", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const tripId = c.req.param("id");
    const { data: existing } = await supabase
      .from("journeys")
      .select("id")
      .eq("trip_id", tripId)
      .neq("user_id", user!.id)
      .in("state", ["started", "in_progress", "planned"])
      .maybeSingle();

    let journeyId = existing?.id;
    if (!journeyId) {
      const { data: created } = await supabase
        .from("journeys")
        .insert({ trip_id: tripId, user_id: user!.id, state: "planned" })
        .select("id")
        .single();
      journeyId = created?.id;
    }

    if (journeyId) {
      await supabase
        .from("journey_participants")
        .insert({ journey_id: journeyId, user_id: user!.id, status: "pending" });
    }

    return json({ joined: true, journeyId });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

// ─── PROFILE ─────────────────────────────────────────────────────────────────

app.get("/api/profile", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const { data, error } = await supabase
      .from("profiles")
      .select("id, handle, display_name, avatar_url, home_base, bio, xp_total, explorer_level, streak_days")
      .eq("id", user!.id)
      .maybeSingle();

    if (error) return errorResponse(error.message, 500);
    return json({ profile: data });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

app.put("/api/profile", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const body = await c.req.json();
    const updates: Record<string, string> = {};
    if (body.display_name) updates.display_name = body.display_name;
    if (body.handle) updates.handle = body.handle;
    if (body.home_base) updates.home_base = body.home_base;
    if (body.bio) updates.bio = body.bio;

    const { data, error } = await supabase
      .from("profiles")
      .update(updates)
      .eq("id", user!.id)
      .select("id, handle, display_name, avatar_url, home_base, bio, xp_total, explorer_level, streak_days")
      .maybeSingle();

    if (error) return errorResponse(error.message, 500);
    return json({ profile: data });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

// ─── GAMIFICATION: XP ────────────────────────────────────────────────────────

app.get("/api/xp", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const { data, error } = await supabase
      .from("xp_transactions")
      .select("id, amount, reason, reference_type, reference_id, created_at")
      .eq("user_id", user!.id)
      .order("created_at", { ascending: false })
      .limit(50);

    if (error) return errorResponse(error.message, 500);
    return json({ transactions: data });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

// ─── GAMIFICATION: BADGES ────────────────────────────────────────────────────

app.get("/api/badges", async (c) => {
  try {
    const user = await getUser(c.req.raw);
    const authResult = requireUser(user);
    if (authResult instanceof Response) return authResult;

    const [allBadges, userBadges] = await Promise.all([
      supabase.from("badges").select("id, name, description, icon, rarity, requirement_key, requirement_description, xp_reward"),
      supabase.from("user_badges").select("badge_id, created_at").eq("user_id", user!.id),
    ]);

    if (allBadges.error) return errorResponse(allBadges.error.message, 500);

    const earnedIds = new Set((userBadges.data ?? []).map((r: { badge_id: string }) => r.badge_id));
    const badges = (allBadges.data ?? []).map((b: Record<string, unknown>) => ({
      ...b,
      earned: earnedIds.has(b.id as string),
    }));

    return json({ badges });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});

// ─── HEALTH CHECK ────────────────────────────────────────────────────────────

app.get("/api/health", (_c) => json({ status: "ok" }));

Deno.serve(app.fetch);
