import { useMemo, useState } from 'react';
import { Routes, Route, useNavigate, useLocation } from 'react-router-dom';
import { ArrowRight, Bell, Bookmark, Check, ChevronRight, Compass, Flame, Heart, Loader2, LogOut, MapPin, MoreHorizontal, Play, Plus, Search, Settings2, Sparkles, Trophy, Users, X } from 'lucide-react';
import { BottomNav, type Page } from '@/components/BottomNav';
import { ChallengeCard } from '@/components/ChallengeCard';
import { ItineraryList } from '@/components/ItineraryList';
import { PlanForm } from '@/components/PlanForm';
import { TripCard } from '@/components/TripCard';
import { TripDetail } from '@/components/TripDetail';
import { AuthPage } from '@/components/AuthPage';
import { useAuth } from '@/lib/auth';
import { useTrips, type Trip, type Destination } from '@/lib/useTrips';
import { useSocial, type Notification } from '@/lib/useSocial';
import { api } from '@/lib/api';
import { challengeOptions, sampleActivities, type PlanInput } from '@/data/travelData';

function getInitials(name: string): string {
  const parts = name.trim().split(/\s+/);
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  return parts[0].slice(0, 2).toUpperCase();
}

function timeAgo(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

function notificationIcon(type: string) {
  if (type === 'follow') return <Users size={13} />;
  if (type === 'trip_liked') return <Heart size={13} />;
  if (type === 'trip_saved') return <Bookmark size={13} />;
  return <Bell size={13} />;
}

function App() {
  const { user, profile, loading, signOut } = useAuth();
  const { trips, destinations, loading: tripsLoading, error: tripsError } = useTrips();
  const social = useSocial(user?.id ?? null);
  const [filter, setFilter] = useState('For you');
  const [selectedTrip, setSelectedTrip] = useState<Trip | null>(null);
  const [plannerMode, setPlannerMode] = useState<'choose' | 'ai' | 'manual' | 'itinerary'>('choose');
  const [planInput, setPlanInput] = useState<PlanInput | null>(null);
  const [completedActivities, setCompletedActivities] = useState<number[]>([0]);
  const [completedChallenges, setCompletedChallenges] = useState<string[]>([]);
  const [activeChallenge, setActiveChallenge] = useState<string | null>(null);
  const [journeyStarted, setJourneyStarted] = useState(true);
  const [showNotifications, setShowNotifications] = useState(false);
  const [joinedTripIds, setJoinedTripIds] = useState<Set<string>>(new Set());

  const featuredTrips = useMemo(() => filter === 'For you' ? trips : trips.filter((trip) => trip.type === filter), [filter, trips]);
  const xp = 1240 + completedActivities.length * 30 + completedChallenges.length * 80;

  const handlePlanSubmit = (input: PlanInput) => { setPlanInput(input); setPlannerMode('itinerary'); };

  const handleJoinJourney = async (trip: Trip) => {
    if (!user) return;
    if (joinedTripIds.has(trip.id)) {
      setJoinedTripIds((prev) => { const n = new Set(prev); n.delete(trip.id); return n; });
      return;
    }
    try {
      await api.joinJourney(trip.id);
      setJoinedTripIds((prev) => new Set(prev).add(trip.id));
    } catch {
      // non-fatal
    }
  };

  if (loading) {
    return <div className="app-loading"><Loader2 size={28} className="spin" /></div>;
  }

  if (!user) {
    return <AuthPage />;
  }

  const displayName = profile?.display_name || user.email?.split('@')[0] || 'Traveler';
  const handle = profile?.handle || 'explorer';
  const initials = getInitials(displayName);
  const firstName = displayName.split(' ')[0];

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand-mark"><span className="brand-symbol"><Compass size={18} /></span><span>roamwell</span></div>
        <div className="topbar-actions">
          <button className="notification-button" onClick={() => { setShowNotifications(!showNotifications); if (!showNotifications && social.unreadCount > 0) social.markAllRead(); }} aria-label="Notifications"><Bell size={19} />{social.unreadCount > 0 && <span className="notif-badge">{social.unreadCount}</span>}</button>
          <div className="topbar-user">
            <span className="avatar top-avatar">{initials}</span>
            <button className="sign-out" onClick={(e) => { e.stopPropagation(); signOut(); }} aria-label="Sign out"><LogOut size={16} /></button>
          </div>
          {showNotifications && <NotificationPopover notifications={social.notifications} onClose={() => setShowNotifications(false)} />}
        </div>
      </header>
      <main className="main-content">
        <Routes>
          <Route path="/" element={
            selectedTrip ? (
              <TripDetail trip={selectedTrip} saved={social.savedTripIds.has(selectedTrip.id)} liked={social.likedTripIds.has(selectedTrip.id)} following={social.followingIds.has(selectedTrip.creatorId)} joined={joinedTripIds.has(selectedTrip.id)} onBack={() => setSelectedTrip(null)} onSave={() => social.toggleSave(selectedTrip.id)} onLike={() => social.toggleLike(selectedTrip.id)} onFollow={() => social.toggleFollow(selectedTrip.creatorId)} onJoin={() => handleJoinJourney(selectedTrip)} />
            ) : (
              <HomePage filter={filter} setFilter={setFilter} trips={featuredTrips} destinations={destinations} loading={tripsLoading} error={tripsError} savedTripIds={social.savedTripIds} likedTripIds={social.likedTripIds} onOpen={setSelectedTrip} onSave={social.toggleSave} onLike={social.toggleLike} journeyStarted={journeyStarted} onExperience={() => {}} firstName={firstName} />
            )
          } />
          <Route path="/create" element={
            plannerMode === 'choose' ? (
              <CreatePage onSelect={setPlannerMode} />
            ) : plannerMode === 'ai' || plannerMode === 'manual' ? (
              <PlanForm mode={plannerMode} onBack={() => setPlannerMode('choose')} onSubmit={handlePlanSubmit} />
            ) : (
              <ItineraryPage input={planInput} activities={sampleActivities} completed={completedActivities} setCompleted={setCompletedActivities} onStart={() => setJourneyStarted(true)} onBack={() => setPlannerMode('choose')} />
            )
          } />
          <Route path="/experience" element={
            <ExperiencePage xp={xp} activeChallenge={activeChallenge} setActiveChallenge={setActiveChallenge} completedChallenges={completedChallenges} onComplete={(id) => { setCompletedChallenges((items) => items.includes(id) ? items : [...items, id]); setActiveChallenge(null); }} />
          } />
          <Route path="/profile" element={
            <ProfilePage xp={xp} savedCount={social.savedTripIds.size} likedCount={social.likedTripIds.size} followingCount={social.followingIds.size} trips={trips} onOpenTrip={setSelectedTrip} displayName={displayName} handle={handle} initials={initials} />
          } />
        </Routes>
      </main>
      <BottomNavWithRouter />
    </div>
  );
}

function BottomNavWithRouter() {
  const navigate = useNavigate();
  const location = useLocation();
  const currentPage: Page = location.pathname === '/create' ? 'create' : location.pathname === '/experience' ? 'experience' : location.pathname === '/profile' ? 'profile' : 'home';
  return <BottomNav page={currentPage} onChange={(page) => {
    const path = page === 'home' ? '/' : `/${page}`;
    navigate(path);
  }} />;
}

function NotificationPopover({ notifications, onClose }: { notifications: Notification[]; onClose: () => void }) {
  return <div className="notification-popover"><div><strong>Notifications</strong><button onClick={onClose}><X size={15} /></button></div>{notifications.length === 0 ? <p className="muted">You're all caught up.</p> : notifications.map((n) => <p key={n.id}><span className={`notification-dot${n.type === 'follow' ? ' gold' : ''}`} /> {notificationIcon(n.type)} <span>{n.message}</span> <span className="notif-time">{timeAgo(n.created_at)}</span></p>)}</div>;
}

type HomePageProps = { filter: string; setFilter: (filter: string) => void; trips: Trip[]; destinations: Destination[]; loading: boolean; error: string | null; savedTripIds: Set<string>; likedTripIds: Set<string>; onOpen: (trip: Trip) => void; onSave: (id: string) => void; onLike: (id: string) => void; journeyStarted: boolean; onExperience: () => void; firstName: string };
function HomePage({ filter, setFilter, trips: visibleTrips, destinations, loading, error, savedTripIds, likedTripIds, onOpen, onSave, onLike, journeyStarted, onExperience, firstName }: HomePageProps) {
  return <div className="home-page">
    <section className="welcome-row"><div><p className="eyebrow">Let's go</p><h1>Where to next,<br /><span>{firstName}?</span></h1></div><button className="filter-button"><Settings2 size={16} /> Preferences</button></section>
    <div className="search-box"><Search size={18} /><span>Search a place, feeling, or experience</span><span className="search-shortcut">⌘ K</span></div>
    {journeyStarted && <section className="journey-banner"><div className="journey-progress"><span className="eyebrow">Your journey · Lisbon</span><strong>Day 2 of 3</strong><div className="progress-track"><span style={{ width: '66%' }} /></div><p><Flame size={14} /> 4 activities waiting for you</p></div><button onClick={onExperience}><Play size={16} fill="currentColor" /> Continue</button></section>}
    <section className="section-block"><div className="section-heading"><div><span className="eyebrow">Made for your mood</span><h2>Find your next feeling</h2></div></div><div className="mood-row"><button><span className="mood-icon amber">☼</span><span>Slow<br />mornings</span></button><button><span className="mood-icon coral">⌁</span><span>City<br />energy</span></button><button><span className="mood-icon teal">◌</span><span>Local<br />flavor</span></button><button><span className="mood-icon blue">↗</span><span>Wild<br />escape</span></button></div></section>
    {destinations.length > 0 && <section className="section-block"><div className="section-heading"><div><span className="eyebrow">Explore India</span><h2>Destinations</h2></div></div><div className="destination-strip">{destinations.map((dest) => <div key={dest.id} className="destination-chip"><img src={dest.coverImage} alt={dest.name} /><div className="destination-chip-overlay" /><span className="destination-chip-name">{dest.name}</span><span className="destination-chip-count">{dest.tripCount} trips</span></div>)}</div></section>}
    <section className="section-block feed-section"><div className="section-heading"><div><span className="eyebrow">Community trips</span><h2>Worth the detour</h2></div></div><div className="filter-row">{['For you', 'Day trip', 'Long weekend', 'Vacay'].map((item) => <button className={filter === item ? 'active' : ''} key={item} onClick={() => setFilter(item)}>{item}</button>)}</div>{loading && <div className="feed-loading"><Loader2 size={24} className="spin" /></div>}{error && <p className="feed-error">Couldn't load trips. {error}</p>}{!loading && !error && <div className="trip-grid">{visibleTrips.map((trip) => <TripCard key={trip.id} trip={trip} saved={savedTripIds.has(trip.id)} liked={likedTripIds.has(trip.id)} onOpen={() => onOpen(trip)} onSave={() => onSave(trip.id)} onLike={() => onLike(trip.id)} />)}</div>}{!loading && !error && visibleTrips.length === 0 && <p className="feed-empty">No trips found for this filter.</p>}</section>
  </div>;
}

function CreatePage({ onSelect }: { onSelect: (mode: 'ai' | 'manual') => void }) {
  return <div className="create-page"><section className="create-hero"><span className="eyebrow">Create plan</span><h1>Make room for<br /><em>the unexpected.</em></h1><p>Whether you want a little guidance or a blank canvas, start with the kind of trip you actually want to remember.</p></section><div className="plan-choice-grid"><button className="plan-choice ai" onClick={() => onSelect('ai')}><span className="choice-icon"><Sparkles size={21} /></span><span className="eyebrow">Recommended</span><h2>Let us plan for you</h2><p>Tell us your pace, budget, and curiosities. We'll find the route between the highlights.</p><span className="choice-link">Start with a feeling <ArrowRight size={16} /></span></button><button className="plan-choice manual" onClick={() => onSelect('manual')}><span className="choice-icon"><Plus size={21} /></span><span className="eyebrow">Your canvas</span><h2>Do it yourself</h2><p>Build it your way, with as much detail as you like. Add places, notes, and time as you go.</p><span className="choice-link">Open a blank plan <ArrowRight size={16} /></span></button></div><div className="create-note"><MapPin size={17} /><span>Every plan comes with local context, not just a list of places.</span></div></div>;
}

type ItineraryPageProps = { input: PlanInput | null; activities: typeof sampleActivities; completed: number[]; setCompleted: React.Dispatch<React.SetStateAction<number[]>>; onStart: () => void; onBack: () => void };
function ItineraryPage({ input, activities, completed, setCompleted, onStart, onBack }: ItineraryPageProps) {
  return <div className="itinerary-page"><button className="back-button" onClick={onBack}>← Change details</button><div className="itinerary-header"><div><span className="eyebrow">Your first draft</span><h1>{input?.destination || 'Your trip'} <span>·</span> {input?.duration || '3 days'}</h1><p>Built for {input?.style.toLowerCase()} · {input?.food.toLowerCase()}</p></div><button className="icon-button"><MoreHorizontal size={19} /></button></div><div className="day-tabs"><button className="active">Day 1 <small>Today</small></button><button>Day 2 <small>Explore</small></button><button>Day 3 <small>Slow down</small></button></div><div className="route-summary"><div><span className="route-dot start" /><span>Graça</span></div><div className="route-line" /><div><span className="route-dot end" /><span>Baixa</span></div><small>3.2 km walking</small></div><ItineraryList activities={activities} completed={completed} onComplete={(index) => setCompleted((items) => items.includes(index) ? items.filter((item) => item !== index) : [...items, index])} /><div className="start-journey-bar"><div><strong>Ready to make it real?</strong><span>Save your draft and start when you arrive.</span></div><button className="primary-button" onClick={onStart}><Play size={16} fill="currentColor" /> Start journey</button></div></div>;
}

type ExperiencePageProps = { xp: number; activeChallenge: string | null; setActiveChallenge: (id: string | null) => void; completedChallenges: string[]; onComplete: (id: string) => void };
function ExperiencePage({ xp, activeChallenge, setActiveChallenge, completedChallenges, onComplete }: ExperiencePageProps) {
  const challenge = challengeOptions.find((item) => item.id === activeChallenge);
  return <div className="experience-page"><section className="experience-hero"><div><span className="eyebrow">Experience · Lisbon</span><h1>Go beyond<br /><em>the postcard.</em></h1><p>Small challenges. Better stories. Earn your way into the places you came to find.</p></div><div className="xp-orb"><span>XP</span><strong>{xp.toLocaleString()}</strong><small>Explorer level 6</small></div></section><div className="streak-card"><div className="streak-icon"><Flame size={20} fill="currentColor" /></div><div><strong>4 day streak</strong><p>One more challenge to keep it going.</p></div><div className="streak-days"><span className="done">M</span><span className="done">T</span><span className="done">W</span><span className="today">T</span><span>F</span><span>S</span><span>S</span></div></div>{challenge ? <ChallengePlay challenge={challenge} onBack={() => setActiveChallenge(null)} onComplete={() => onComplete(challenge.id)} completed={completedChallenges.includes(challenge.id)} /> : <section className="challenge-section"><div className="section-heading"><div><span className="eyebrow">Pick your path</span><h2>What are you curious about?</h2></div><span className="challenge-count">{completedChallenges.length}/4 complete</span></div><div className="challenge-grid">{challengeOptions.map((item) => <div key={item.id} className="challenge-wrap"><ChallengeCard {...item} onClick={() => setActiveChallenge(item.id)} />{completedChallenges.includes(item.id) && <span className="completed-badge"><Check size={12} /> Complete</span>}</div>)}</div><div className="badge-preview"><div className="badge-medal"><Trophy size={24} /></div><div><span className="eyebrow">Next unlock</span><strong>Streetwise</strong><p>Complete two map challenges</p></div><ChevronRight size={18} /></div></section>}</div>;
}

function ChallengePlay({ challenge, onBack, onComplete, completed }: { challenge: typeof challengeOptions[number]; onBack: () => void; onComplete: () => void; completed: boolean }) {
  return <section className="challenge-play"><button className="back-button" onClick={onBack}>← All challenges</button><div className="challenge-play-top"><span className="eyebrow">{challenge.label} · 01</span><span className="challenge-xp">+80 XP</span></div><h2>{challenge.id === 'history' ? `Why are Lisbon's sidewalks made of small stones?` : challenge.id === 'language' ? `How do you say "thank you" in Portuguese?` : challenge.id === 'map' ? `Which route gets you to Alfama with the best views?` : `Which detail belongs to Lisbon?`}</h2><p className="challenge-prompt">Take a guess. The best way to learn a place is to be a little wrong in it.</p><div className="answer-list">{(challenge.id === 'history' ? ['They help drain rainwater', 'They were made from old ship ballast', 'They are easier to repair'] : challenge.id === 'language' ? ['Olá', 'Obrigado', 'Saúde'] : challenge.id === 'map' ? ['The riverside road', 'The uphill route through Graça', 'The main avenue'] : ['Blue azulejo tiles', 'Red London phone boxes', 'Wooden torii gates']).map((answer, index) => <button key={answer} onClick={index === 1 ? onComplete : undefined} className={completed && index === 1 ? 'correct' : ''}><span>{String.fromCharCode(65 + index)}</span>{answer}{completed && index === 1 && <Check size={17} />}</button>)}</div>{completed && <div className="success-message"><Sparkles size={18} /><div><strong>Nice instinct.</strong><span>That's the local answer. +80 XP added to your explorer score.</span></div></div>}</section>;
}

type ProfilePageProps = { xp: number; savedCount: number; likedCount: number; followingCount: number; trips: Trip[]; onOpenTrip: (trip: Trip) => void; displayName: string; handle: string; initials: string };
function ProfilePage({ xp, savedCount, likedCount, followingCount, trips, onOpenTrip, displayName, handle, initials }: ProfilePageProps) {
  return <div className="profile-page"><div className="profile-heading"><div><span className="eyebrow">Your space</span><h1>Profile</h1></div><button className="icon-button"><Settings2 size={19} /></button></div><section className="profile-card"><div className="profile-top"><div className="avatar large">{initials}</div><div><h2>{displayName}</h2><p>@{handle}</p></div><button className="outline-button">Edit profile</button></div><div className="profile-stats"><div><strong>{xp.toLocaleString()}</strong><span>XP earned</span></div><div><strong>{followingCount}</strong><span>following</span></div><div><strong>{savedCount}</strong><span>saved</span></div></div></section><section className="profile-section"><div className="section-heading"><div><span className="eyebrow">Keep exploring</span><h2>Your progress</h2></div><Trophy size={19} className="gold-icon" /></div><div className="level-track"><div className="level-label"><span>Explorer level 6</span><strong>1,240 / 2,000 XP</strong></div><div className="progress-track"><span style={{ width: '62%' }} /></div></div><div className="badge-row"><div className="badge-item unlocked"><Trophy size={19} /><span>First steps</span></div><div className="badge-item unlocked"><Flame size={19} /><span>On a roll</span></div><div className="badge-item"><Sparkles size={19} /><span>Streetwise</span></div><div className="badge-item"><Plus size={19} /><span>Explorer</span></div></div></section><section className="profile-section"><div className="section-heading"><div><span className="eyebrow">Your library</span><h2>Trips & journeys</h2></div></div><div className="library-list"><button onClick={() => trips[0] && onOpenTrip(trips[0])}><span className="library-icon coral"><Bookmark size={18} /></span><span><strong>Saved trips</strong><small>{savedCount} trips waiting for you</small></span><ChevronRight size={17} /></button><button><span className="library-icon teal"><Compass size={18} /></span><span><strong>Created trips</strong><small>2 plans · 1 draft</small></span><ChevronRight size={17} /></button><button><span className="library-icon amber"><Sparkles size={18} /></span><span><strong>Experience progress</strong><small>{likedCount + 3} challenges completed</small></span><ChevronRight size={17} /></button></div></section></div>;
}

export default App;
