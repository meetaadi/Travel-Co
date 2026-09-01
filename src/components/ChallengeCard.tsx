import { ArrowRight, Languages, Landmark, Map, ScanSearch } from 'lucide-react';

type ChallengeCardProps = { label: string; icon: string; count: number; color: string; description: string; onClick: () => void };

const iconMap = { landmark: Landmark, scan: ScanSearch, languages: Languages, map: Map };

export function ChallengeCard({ label, icon, count, color, description, onClick }: ChallengeCardProps) {
  const Icon = iconMap[icon as keyof typeof iconMap] ?? Landmark;
  return <button className="challenge-card" onClick={onClick} style={{ '--challenge-color': color } as React.CSSProperties}><span className="challenge-icon"><Icon size={20} /></span><span className="challenge-copy"><strong>{label}</strong><small>{description}</small><em>{count} challenges</em></span><ArrowRight size={18} className="challenge-arrow" /></button>;
}
