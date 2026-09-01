import { Bookmark, Heart, MapPin, Users } from 'lucide-react';
import type { Trip } from '@/data/travelData';

type TripCardProps = {
  trip: Trip;
  saved: boolean;
  liked: boolean;
  onOpen: () => void;
  onSave: () => void;
  onLike: () => void;
};

export function TripCard({ trip, saved, liked, onOpen, onSave, onLike }: TripCardProps) {
  return (
    <article className="trip-card">
      <button className="trip-image-button" onClick={onOpen} aria-label={`View ${trip.title}`}>
        <img className="trip-image" src={trip.image} alt={`${trip.destination} travel`} />
        <span className="trip-type">{trip.type}</span>
        <span className="image-fade" />
        <span className="trip-destination"><MapPin size={13} /> {trip.destination}</span>
      </button>
      <div className="trip-body">
        <div className="trip-title-row">
          <div>
            <h3>{trip.title}</h3>
            <p className="muted">{trip.duration} <span className="dot">·</span> {trip.budget} est.</p>
          </div>
          <button className={`icon-button ${saved ? 'selected' : ''}`} onClick={onSave} aria-label={saved ? 'Remove saved trip' : 'Save trip'}>
            <Bookmark size={18} fill={saved ? 'currentColor' : 'none'} />
          </button>
        </div>
        <p className="trip-blurb">{trip.blurb}</p>
        <div className="trip-meta">
          <div className="creator"><span className="avatar small">{trip.initials}</span><span>{trip.creator}</span></div>
          <span className="traveler-count"><Users size={14} /> {trip.travelers}</span>
          <button className={`like-button ${liked ? 'liked' : ''}`} onClick={onLike} aria-label={liked ? 'Unlike trip' : 'Like trip'}><Heart size={15} fill={liked ? 'currentColor' : 'none'} /> {trip.likes}</button>
        </div>
      </div>
    </article>
  );
}
