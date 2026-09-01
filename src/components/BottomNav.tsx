import { Compass, Map, Plus, Sparkles, UserRound } from 'lucide-react';
import { NavLink } from 'react-router-dom';

type Page = 'home' | 'create' | 'experience' | 'profile';

type BottomNavProps = {
  page: Page;
  onChange: (page: Page) => void;
};

const items: Array<{ id: Page; path: string; label: string; icon: typeof Compass }> = [
  { id: 'home', path: '/', label: 'Explore', icon: Compass },
  { id: 'create', path: '/create', label: 'Create plan', icon: Plus },
  { id: 'experience', path: '/experience', label: 'Experience', icon: Sparkles },
  { id: 'profile', path: '/profile', label: 'Profile', icon: UserRound },
];

export function BottomNav({ onChange }: BottomNavProps) {
  return (
    <nav className="bottom-nav" aria-label="Primary navigation">
      <div className="nav-inner">
        {items.map(({ id, path, label, icon: Icon }) => (
          <NavLink
            key={id}
            to={path}
            className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
            onClick={() => onChange(id)}
            aria-current={undefined}
          >
            {({ isActive }) => (
              <>
                <Icon size={19} strokeWidth={isActive ? 2.4 : 1.8} />
                <span>{label}</span>
              </>
            )}
          </NavLink>
        ))}
      </div>
    </nav>
  );
}

export type { Page };
