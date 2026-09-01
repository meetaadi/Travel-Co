import { supabase } from '@/lib/supabase';

const API_URL = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/api`;

async function getToken(): Promise<string | null> {
  const { data } = await supabase.auth.getSession();
  return data.session?.access_token ?? null;
}

async function request<T>(
  path: string,
  options: {
    method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
    body?: unknown;
  } = {},
): Promise<T> {
  const token = await getToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    apikey: import.meta.env.VITE_SUPABASE_ANON_KEY as string,
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const response = await fetch(`${API_URL}${path}`, {
    method: options.method ?? 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  if (!response.ok) {
    let message = `Request failed (${response.status})`;
    try {
      const body = await response.json();
      if (body.error) message = body.error;
    } catch {
      // ignore parse errors
    }
    throw new Error(message);
  }

  return response.json() as Promise<T>;
}

// ─── Types ───────────────────────────────────────────────────────────────────

export type ApiTrip = {
  id: string;
  title: string;
  type: string;
  duration_days: number;
  budget_text: string | null;
  travelers: number;
  blurb: string | null;
  cover_image: string | null;
  experiences: string[] | null;
  local_note: string | null;
  destination_id: string | null;
  user_id: string;
  destinations: { name: string; country: string } | null;
  profiles: { display_name: string; handle: string } | null;
  trip_likes: { count: number }[];
  trip_saves: { count: number }[];
};

export type ApiDestination = {
  id: string;
  name: string;
  country: string;
  slug: string;
  blurb: string | null;
  cover_image: string | null;
};

export type ApiNotification = {
  id: string;
  type: string;
  message: string | null;
  read: boolean;
  created_at: string;
  actor_id: string | null;
};

export type ApiProfile = {
  id: string;
  handle: string;
  display_name: string;
  avatar_url: string | null;
  home_base: string | null;
  bio: string | null;
  xp_total: number;
  explorer_level: number;
  streak_days: number;
};

export type ApiBadge = {
  id: string;
  name: string;
  description: string;
  icon: string;
  rarity: string;
  requirement_key: string;
  requirement_description: string;
  xp_reward: number;
  earned: boolean;
};

export type ApiXpTransaction = {
  id: string;
  amount: number;
  reason: string;
  reference_type: string | null;
  reference_id: string | null;
  created_at: string;
};

// ─── API Methods ─────────────────────────────────────────────────────────────

export const api = {
  // Trips
  getTrips: (type?: string) =>
    request<{ trips: ApiTrip[] }>(`/trips${type ? `?type=${encodeURIComponent(type)}` : ''}`),

  getTrip: (id: string) =>
    request<{ trip: ApiTrip }>(`/trips/${id}`),

  createTrip: (data: {
    destination_id?: string;
    title: string;
    type: string;
    duration_days: number;
    budget_text?: string;
    travelers?: number;
    blurb?: string;
    cover_image?: string;
    experiences?: string[];
    local_note?: string;
    status?: string;
  }) => request<{ trip: { id: string } }>('/trips', { method: 'POST', body: data }),

  // Destinations
  getDestinations: () =>
    request<{ destinations: ApiDestination[] }>('/destinations'),

  // Social — likes
  likeTrip: (tripId: string) =>
    request<{ liked: boolean }>(`/trips/${tripId}/like`, { method: 'POST' }),

  unlikeTrip: (tripId: string) =>
    request<{ liked: boolean }>(`/trips/${tripId}/like`, { method: 'DELETE' }),

  // Social — saves
  saveTrip: (tripId: string) =>
    request<{ saved: boolean }>(`/trips/${tripId}/save`, { method: 'POST' }),

  unsaveTrip: (tripId: string) =>
    request<{ saved: boolean }>(`/trips/${tripId}/save`, { method: 'DELETE' }),

  // Social — follows
  followUser: (targetId: string) =>
    request<{ following: boolean }>(`/follows/${targetId}`, { method: 'POST' }),

  unfollowUser: (targetId: string) =>
    request<{ following: boolean }>(`/follows/${targetId}`, { method: 'DELETE' }),

  // Social — user state
  getMySocial: () =>
    request<{ likedTripIds: string[]; savedTripIds: string[]; followingIds: string[] }>('/social/me'),

  // Notifications
  getNotifications: (limit = 20) =>
    request<{ notifications: ApiNotification[] }>(`/notifications?limit=${limit}`),

  getUnreadCount: () =>
    request<{ unreadCount: number }>('/notifications/unread-count'),

  markAllNotificationsRead: () =>
    request<{ success: boolean }>('/notifications/read-all', { method: 'PUT' }),

  // Journeys
  joinJourney: (tripId: string) =>
    request<{ joined: boolean; journeyId: string }>(`/trips/${tripId}/join`, { method: 'POST' }),

  // Profile
  getProfile: () =>
    request<{ profile: ApiProfile | null }>('/profile'),

  updateProfile: (data: {
    display_name?: string;
    handle?: string;
    home_base?: string;
    bio?: string;
  }) => request<{ profile: ApiProfile | null }>('/profile', { method: 'PUT', body: data }),

  // Gamification
  getXpTransactions: () =>
    request<{ transactions: ApiXpTransaction[] }>('/xp'),

  getBadges: () =>
    request<{ badges: ApiBadge[] }>('/badges'),

  // Health
  health: () => request<{ status: string }>('/health'),
};
