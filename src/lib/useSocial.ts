import { useCallback, useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { api, type ApiNotification } from '@/lib/api';

export type Notification = {
  id: string;
  type: string;
  message: string | null;
  read: boolean;
  created_at: string;
  actor_id: string | null;
};

export function useSocial(userId: string | null) {
  const [likedTripIds, setLikedTripIds] = useState<Set<string>>(new Set());
  const [savedTripIds, setSavedTripIds] = useState<Set<string>>(new Set());
  const [followingIds, setFollowingIds] = useState<Set<string>>(new Set());
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);

  const loadAll = useCallback(async () => {
    if (!userId) return;
    try {
      const [socialRes, notifRes, unreadRes] = await Promise.all([
        api.getMySocial(),
        api.getNotifications(),
        api.getUnreadCount(),
      ]);

      setLikedTripIds(new Set(socialRes.likedTripIds));
      setSavedTripIds(new Set(socialRes.savedTripIds));
      setFollowingIds(new Set(socialRes.followingIds));
      setNotifications(notifRes.notifications as Notification[]);
      setUnreadCount(unreadRes.unreadCount);
    } catch {
      // network errors are non-fatal for social state
    }
  }, [userId]);

  useEffect(() => {
    if (!userId) {
      setLikedTripIds(new Set());
      setSavedTripIds(new Set());
      setFollowingIds(new Set());
      setNotifications([]);
      setUnreadCount(0);
      return;
    }
    loadAll();

    let channelClosed = false;

    const channel = supabase
      .channel(`social:${userId}`)
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'notifications', filter: `user_id=eq.${userId}` },
        (payload) => {
          const n = payload.new as Notification;
          setNotifications((prev) => [n, ...prev].slice(0, 20));
          setUnreadCount((prev) => prev + 1);
        },
      )
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: 'notifications', filter: `user_id=eq.${userId}` },
        () => {
          if (!channelClosed) loadAll();
        },
      )
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'trip_likes', filter: `user_id=eq.${userId}` },
        (payload) => {
          const row = payload.new as { trip_id: string };
          setLikedTripIds((prev) => new Set(prev).add(row.trip_id));
        },
      )
      .on(
        'postgres_changes',
        { event: 'DELETE', schema: 'public', table: 'trip_likes', filter: `user_id=eq.${userId}` },
        () => {
          if (!channelClosed) loadAll();
        },
      )
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'trip_saves', filter: `user_id=eq.${userId}` },
        (payload) => {
          const row = payload.new as { trip_id: string };
          setSavedTripIds((prev) => new Set(prev).add(row.trip_id));
        },
      )
      .on(
        'postgres_changes',
        { event: 'DELETE', schema: 'public', table: 'trip_saves', filter: `user_id=eq.${userId}` },
        () => {
          if (!channelClosed) loadAll();
        },
      )
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'user_follows', filter: `follower_id=eq.${userId}` },
        (payload) => {
          const row = payload.new as { following_id: string };
          setFollowingIds((prev) => new Set(prev).add(row.following_id));
        },
      )
      .on(
        'postgres_changes',
        { event: 'DELETE', schema: 'public', table: 'user_follows', filter: `follower_id=eq.${userId}` },
        () => {
          if (!channelClosed) loadAll();
        },
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
  }, [userId, loadAll]);

  const toggleLike = useCallback(
    async (tripId: string) => {
      if (!userId) return;
      const isLiked = likedTripIds.has(tripId);
      setLikedTripIds((prev) => {
        const next = new Set(prev);
        if (isLiked) next.delete(tripId);
        else next.add(tripId);
        return next;
      });
      try {
        if (isLiked) {
          await api.unlikeTrip(tripId);
        } else {
          await api.likeTrip(tripId);
        }
      } catch {
        setLikedTripIds((prev) => {
          const next = new Set(prev);
          if (isLiked) next.add(tripId);
          else next.delete(tripId);
          return next;
        });
      }
    },
    [userId, likedTripIds],
  );

  const toggleSave = useCallback(
    async (tripId: string) => {
      if (!userId) return;
      const isSaved = savedTripIds.has(tripId);
      setSavedTripIds((prev) => {
        const next = new Set(prev);
        if (isSaved) next.delete(tripId);
        else next.add(tripId);
        return next;
      });
      try {
        if (isSaved) {
          await api.unsaveTrip(tripId);
        } else {
          await api.saveTrip(tripId);
        }
      } catch {
        setSavedTripIds((prev) => {
          const next = new Set(prev);
          if (isSaved) next.add(tripId);
          else next.delete(tripId);
          return next;
        });
      }
    },
    [userId, savedTripIds],
  );

  const toggleFollow = useCallback(
    async (targetUserId: string) => {
      if (!userId || userId === targetUserId) return;
      const isFollowing = followingIds.has(targetUserId);
      setFollowingIds((prev) => {
        const next = new Set(prev);
        if (isFollowing) next.delete(targetUserId);
        else next.add(targetUserId);
        return next;
      });
      try {
        if (isFollowing) {
          await api.unfollowUser(targetUserId);
        } else {
          await api.followUser(targetUserId);
        }
      } catch {
        setFollowingIds((prev) => {
          const next = new Set(prev);
          if (isFollowing) next.add(targetUserId);
          else next.delete(targetUserId);
          return next;
        });
      }
    },
    [userId, followingIds],
  );

  const markAllRead = useCallback(async () => {
    if (!userId) return;
    setUnreadCount(0);
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
    try {
      await api.markAllNotificationsRead();
    } catch {
      // non-fatal
    }
  }, [userId]);

  return {
    likedTripIds,
    savedTripIds,
    followingIds,
    notifications,
    unreadCount,
    toggleLike,
    toggleSave,
    toggleFollow,
    markAllRead,
  };
}
