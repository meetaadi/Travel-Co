import { Check, Clock3, Coffee, Footprints, MapPin, TrainFront } from 'lucide-react';
import type { Activity } from '@/data/travelData';

type ItineraryListProps = { activities: Activity[]; completed: number[]; onComplete: (index: number) => void };

const icons = { 'Local start': Coffee, Walk: Footprints, Eat: Coffee, Move: TrainFront };

export function ItineraryList({ activities, completed, onComplete }: ItineraryListProps) {
  return <div className="itinerary-list">
    {activities.map((activity, index) => {
      const Icon = icons[activity.kind as keyof typeof icons] ?? Clock3;
      const isComplete = completed.includes(index);
      return <div className={`activity-row ${isComplete ? 'complete' : ''}`} key={`${activity.time}-${activity.title}`}>
        <div className="activity-time">{activity.time}</div>
        <div className="activity-line"><span className="activity-dot" /><span className="activity-stem" /></div>
        <div className="activity-card">
          <div className="activity-icon"><Icon size={17} /></div>
          <div className="activity-content"><div className="activity-heading"><div><h4>{activity.title}</h4><p><MapPin size={12} /> {activity.place}</p></div><span className="activity-kind">{activity.kind}</span></div><p className="activity-detail">{activity.detail}</p><div className="activity-footer"><span>{activity.cost}</span><button className={`complete-button ${isComplete ? 'done' : ''}`} onClick={() => onComplete(index)}>{isComplete ? <><Check size={13} /> Done</> : 'Complete'}</button></div></div>
        </div>
      </div>;
    })}
  </div>;
}
