import type { Trip } from '@/lib/useTrips';
export type { TripType, Trip } from '@/lib/useTrips';

export type PlanInput = {
  destination: string;
  duration: string;
  budget: string;
  travelers: string;
  food: string;
  style: string;
};

export type Activity = {
  time: string;
  title: string;
  place: string;
  detail: string;
  cost: string;
  kind: string;
};

export const trips: Trip[] = [
  {
    id: 'lisbon-after-hours',
    destination: 'Lisbon',
    country: 'Portugal',
    title: 'Lisbon after hours',
    type: 'Long weekend',
    duration: '3 days',
    budget: '$680',
    travelers: 2,
    creator: 'Maya Chen',
    creatorId: '',
    handle: '@mayamoves',
    initials: 'MC',
    image: 'https://images.pexels.com/photos/13091850/pexels-photo-13091850.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
    likes: 428,
    saves: 52,
    experiences: ['Sunset tram rides', 'Petiscos crawl', 'Quiet viewpoints'],
    blurb: 'A slower Lisbon with the best light, tiny tables, and the hills worth climbing.',
    localNote: 'Skip Tram 28 at noon. Start at Graça after 5pm and walk downhill with the light behind you.',
  },
  {
    id: 'tokyo-side-streets',
    destination: 'Tokyo',
    country: 'Japan',
    title: 'Tokyo side streets',
    type: 'Vacay',
    duration: '7 days',
    budget: '$1,940',
    travelers: 3,
    creator: 'Noah Williams',
    creatorId: '',
    handle: '@noahnorth',
    initials: 'NW',
    image: 'https://images.pexels.com/photos/30780336/pexels-photo-30780336.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
    likes: 716,
    saves: 98,
    experiences: ['Late-night ramen', 'Vinyl listening bars', 'Temple mornings'],
    blurb: 'Trade the checklist for tiny bars, early temples, and neighborhoods with their own rhythm.',
    localNote: 'The best ramen queues move quickly after 10pm. Bring cash and order the chef special.',
  },
  {
    id: 'amalfi-at-ease',
    destination: 'Amalfi Coast',
    country: 'Italy',
    title: 'Amalfi at ease',
    type: 'Day trip',
    duration: '1 day',
    budget: '$210',
    travelers: 4,
    creator: 'Sara Rossi',
    creatorId: '',
    handle: '@sarawanders',
    initials: 'SR',
    image: 'https://images.pexels.com/photos/17855614/pexels-photo-17855614.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
    likes: 289,
    saves: 31,
    experiences: ['Ferry views', 'Lemon granita', 'Cliffside swims'],
    blurb: 'A one-day coast route that avoids the traffic and leaves room for one perfect swim.',
    localNote: 'Take the first ferry from Salerno. The coast road is a view, not a shortcut.',
  },
];

export const sampleActivities: Activity[] = [
  { time: '09:00', title: 'Coffee with a view', place: 'Miradouro da Senhora do Monte', detail: 'Start above the city while the streets are still quiet.', cost: '$8', kind: 'Local start' },
  { time: '11:30', title: 'Wander Alfama', place: 'Rua de São Miguel', detail: 'Follow the tiled lanes downhill; pause where the laundry hangs.', cost: '$0', kind: 'Walk' },
  { time: '14:00', title: 'Petiscos lunch', place: 'O Velho Eurico', detail: 'Book a counter seat and share three small plates.', cost: '$28', kind: 'Eat' },
  { time: '17:20', title: 'Golden-hour tram', place: 'Graça → Baixa', detail: 'Take the scenic route after the day-trippers leave.', cost: '$4', kind: 'Move' },
];

export const challengeOptions = [
  { id: 'history', label: 'History', icon: 'landmark', count: 12, color: '#d9a441', description: 'Unpack the stories behind the streets.' },
  { id: 'identify', label: 'Identify', icon: 'scan', count: 8, color: '#ef6c56', description: 'Spot the details most people walk past.' },
  { id: 'language', label: 'Language', icon: 'languages', count: 10, color: '#68a6a0', description: 'Learn the words that open doors.' },
  { id: 'map', label: 'Map challenge', icon: 'map', count: 6, color: '#7c8fb8', description: 'Find the smarter way through the city.' },
];
