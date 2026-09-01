import React, { useState } from 'react';
import { ArrowRight, ChevronLeft, Sparkles } from 'lucide-react';
import type { PlanInput } from '@/data/travelData';

type PlanFormProps = { mode: 'ai' | 'manual'; onBack: () => void; onSubmit: (input: PlanInput) => void };

export function PlanForm({ mode, onBack, onSubmit }: PlanFormProps) {
  const [form, setForm] = useState<PlanInput>({ destination: '', duration: '3 days', budget: '$500 – $1,000', travelers: '2 travelers', food: 'Local food', style: 'Slow & curious' });
  const update = (key: keyof PlanInput, value: string) => setForm((current) => ({ ...current, [key]: value }));
  const canSubmit = mode === 'ai' || form.destination.trim().length > 0;

  return (
    <section className="plan-form-screen">
      <button className="back-button" onClick={onBack}><ChevronLeft size={18} /> Back</button>
      <div className="form-intro">
        <span className="eyebrow">{mode === 'ai' ? 'Let us plan for you' : 'Do it yourself'}</span>
        <h1>{mode === 'ai' ? 'Tell us how you like to travel.' : 'Build a trip that feels like yours.'}</h1>
        <p>{mode === 'ai' ? 'We’ll shape a day-by-day route around your time, budget, and appetite for discovery.' : 'Start with the essentials. You can add places, times, notes, and transport as you go.'}</p>
      </div>
      <div className="form-fields">
        <label>
          <span className="optional-label">
            Where are you going?
            {mode === 'ai' && <em className="optional-tag">Optional</em>}
          </span>
          <input value={form.destination} onChange={(event) => update('destination', event.target.value)} placeholder={mode === 'ai' ? 'Surprise me — or try Lisbon, Pune, Tokyo' : 'Try Lisbon, Portugal'} />
        </label>
        <div className="field-grid">
          <label>How long?
            <select value={form.duration} onChange={(event) => update('duration', event.target.value)}><option>1 day</option><option>3 days</option><option>5 days</option><option>7 days</option></select>
          </label>
          <label>Budget
            <select value={form.budget} onChange={(event) => update('budget', event.target.value)}><option>$250 – $500</option><option>$500 – $1,000</option><option>$1,000 – $2,000</option><option>$2,000+</option></select>
          </label>
        </div>
        <div className="field-grid">
          <label>Who’s coming?
            <select value={form.travelers} onChange={(event) => update('travelers', event.target.value)}><option>Solo traveler</option><option>2 travelers</option><option>3–4 travelers</option><option>5+ travelers</option></select>
          </label>
          <label>Food mood
            <select value={form.food} onChange={(event) => update('food', event.target.value)}><option>Local food</option><option>Vegetarian</option><option>Vegan</option><option>Anything goes</option></select>
          </label>
        </div>
        <label>Travel personality
          <select value={form.style} onChange={(event) => update('style', event.target.value)}><option>Slow & curious</option><option>Big energy</option><option>Culture seeker</option><option>Nature first</option></select>
        </label>
      </div>
      <button className="primary-button full" disabled={!canSubmit} onClick={() => onSubmit(form)}>
        {mode === 'ai' ? <><Sparkles size={17} /> Create my itinerary</> : <>Start building <ArrowRight size={17} /></>}
      </button>
    </section>
  );
}
