import { useCallback, useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { api, type ApiTrip, type ApiDestination } from '@/lib/api';

export type TripType = 'Day trip' | 'Long weekend' | 'Vacay';

export type Trip = {
  id: string;
  destination: string;
  country: string;
  title: string;
  type: TripType;
  duration: string;
  budget: string;
  travelers: number;
  creator: string;
  creatorId: string;
  handle: string;
  initials: string;
  image: string;
  likes: number;
  saves: number;
  experiences: string[];
  blurb: string;
  localNote: string;
};

export type Destination = {
  id: string;
  name: string;
  country: string;
  slug: string;
  blurb: string;
  coverImage: string;
  tripCount: number;
};

function getInitials(name: string): string {
  const parts = name.trim().split(/\s+/);
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  return parts[0].slice(0, 2).toUpperCase();
}

function durationLabel(days: number): string {
  if (days === 1) return '1 day';
  return `${days} days`;
}

function normalizeTrip(raw: ApiTrip): Trip {
  const dest = raw.destinations;
  const prof = raw.profiles;
  const creatorName = prof?.display_name ?? 'Traveler';
  return {
    id: raw.id,
    destination: dest?.name ?? 'Unknown',
    country: dest?.country ?? 'India',
    title: raw.title,
    type: raw.type as TripType,
    duration: durationLabel(raw.duration_days),
    budget: raw.budget_text ?? '',
    travelers: raw.travelers,
    creator: creatorName,
    creatorId: raw.user_id,
    handle: prof?.handle ? `@${prof.handle}` : '@explorer',
    initials: getInitials(creatorName),
    image: raw.cover_image ?? '',
    likes: raw.trip_likes?.[0]?.count ?? 0,
    saves: raw.trip_saves?.[0]?.count ?? 0,
    experiences: raw.experiences ?? [],
    blurb: raw.blurb ?? '',
    localNote: raw.local_note ?? '',
  };
}

export function useTrips() {
  const [trips, setTrips] = useState<Trip[]>([]);
  const [destinations, setDestinations] = useState<Destination[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAll = useCallback(async () => {
    try {
      const [tripsRes, destRes] = await Promise.all([
        api.getTrips(),
        api.getDestinations(),
      ]);

      const normalized = tripsRes.trips.map(normalizeTrip);
      setTrips(normalized);

      const tripCounts = new Map<string, number>();
      for (const raw of tripsRes.trips) {
        if (raw.destination_id) {
          tripCounts.set(raw.destination_id, (tripCounts.get(raw.destination_id) ?? 0) + 1);
        }
      }
      setDestinations(
        destRes.destinations
          .filter((d) => (tripCounts.get(d.id) ?? 0) > 0)
          .map((d: ApiDestination) => ({
            id: d.id,
            name: d.name,
            country: d.country,
            slug: d.slug,
            blurb: d.blurb ?? '',
            coverImage: d.cover_image ?? '',
            tripCount: tripCounts.get(d.id) ?? 0,
          })),
      );

      setLoading(false);
    } catch (err) {
      setError((err as Error).message);
      setLoading(false);
    }
  }, []);

  const refreshTripCounts = useCallback(async () => {
    const tripsRes = await api.getTrips();
    const counts = new Map<string, { likes: number; saves: number }>();
    for (const raw of tripsRes.trips) {
      counts.set(raw.id, {
        likes: raw.trip_likes?.[0]?.count ?? 0,
        saves: raw.trip_saves?.[0]?.count ?? 0,
      });
    }
    setTrips((prev) => prev.map((t) => {
      const c = counts.get(t.id);
      if (!c) return t;
      if (t.likes === c.likes && t.saves === c.saves) return t;
      return { ...t, likes: c.likes, saves: c.saves };
    }));
  }, []);

  useEffect(() => {
    fetchAll();

    let channelClosed = false;

    const channel = supabase
      .channel('trip-counts')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'trip_likes' },
        () => { if (!channelClosed) refreshTripCounts(); },
      )
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'trip_saves' },
        () => { if (!channelClosed) refreshTripCounts(); },
      )
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'trips', filter: 'status=eq.published' },
        () => { if (!channelClosed) fetchAll(); },
      )
      .subscribe((status) => {
        if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') {
          channelClosed = true;
        }
      });

    return () => {
      channelClosed = true;
      supabase.removeChannel(channel);
    };
  }, [fetchAll, refreshTripCounts]);

  return { trips, destinations, loading, error };
}
