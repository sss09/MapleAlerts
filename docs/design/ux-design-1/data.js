/* MapleAlerts — mock data + simple line-icon set (plain JS, attaches to window) */
(function () {
// ── Simple, single-purpose UI icons (geometric strokes only) ──────────────
// Rendered by <Icon> in ui.jsx. viewBox 24×24, stroke-based.
const ICONS = {
  health:   'M12 20.5C7 17 3.5 13.8 3.5 9.8 3.5 7.1 5.5 5.5 7.6 5.5c1.6 0 3 .9 3.6 2.2.6-1.3 2-2.2 3.6-2.2 2.1 0 4.1 1.6 4.1 4.3 0 4-3.5 7.2-8.5 10.7z',
  vehicle:  'M4 13l1.5-4.2A2 2 0 017.4 7.5h7.2a2 2 0 011.9 1.3L18 13M4 13h14M4 13v3.5h2.2M18 13v3.5h-2.2M6.2 16.5a1.4 1.4 0 11-2.8 0 1.4 1.4 0 012.8 0zm12.4 0a1.4 1.4 0 11-2.8 0 1.4 1.4 0 012.8 0z',
  gov:      'M5 9.5h12M6 9.5v6m4-6v6m4-6v6m3 0H4m13-9.5L11 3 5 6v1.2h12z',
  bill:     'M13 2.5L4 14h6.5L9.5 21.5 19 9.5h-6.5l.5-7z',
  finance:  'M11 4.5v12M8 8.2c0-1.2 1.3-1.9 3-1.9s3 .7 3 1.9-1.3 1.9-3 1.9-3 .7-3 1.9 1.3 1.9 3 1.9 3-.7 3-1.9',
  home:     'M4 10.5L11 4.5l7 6M5.5 9.2V17h11V9.2M9 17v-4.2h4V17',
  passport: 'M6 3.5h9l3 3V19a1.5 1.5 0 01-1.5 1.5h-9A1.5 1.5 0 016 19V5a1.5 1.5 0 01.5-1.5zM9 9.5h5M9 12.5h5M9 15.5h3',
  rx:       'M7.5 11.5l7 7M7 7.5h4.5a3 3 0 010 6H7v-6zm0 6v5',
  seasonal: 'M11 3v16M11 3v16M4.2 7l13.6 9M4.2 16l13.6-9M11 5.5l-2 1.5m2-1.5l2 1.5M11 17.5l-2-1.5m2 1.5l2-1.5M5 8.6l.4 2.4M5 8.6l-2 .9m14.6 5.4l-.4-2.4m.4 2.4l2-.9',
  family:   'M8 9.5a2.2 2.2 0 100-4.4 2.2 2.2 0 000 4.4zM4 18v-1c0-2.2 1.8-3.5 4-3.5s4 1.3 4 3.5v1M15 10a1.8 1.8 0 100-3.6M14 18v-1c0-1.6.8-2.7 2.2-3.2',
  bell:     'M11 4.2a4.6 4.6 0 00-4.6 4.6c0 4-1.4 5.2-1.4 5.2h12s-1.4-1.2-1.4-5.2A4.6 4.6 0 0011 4.2zM9.3 17a1.8 1.8 0 003.4 0',
  calendar: 'M5 6.5h12v11H5v-11zM5 9.5h12M8 4.5v3m6-3v3',
  plus:     'M11 5v12M5 11h12',
  sparkle:  'M11 4l1.4 4.1L16.5 9.5l-4.1 1.4L11 15l-1.4-4.1L5.5 9.5l4.1-1.4L11 4z',
  mic:      'M11 4.5a2.2 2.2 0 012.2 2.2v4a2.2 2.2 0 11-4.4 0v-4A2.2 2.2 0 0111 4.5zM6.5 10.5a4.5 4.5 0 009 0M11 15v2.5',
  scan:     'M5 8V6.2A1.2 1.2 0 016.2 5H8m6 0h1.8A1.2 1.2 0 0117 6.2V8m0 6v1.8a1.2 1.2 0 01-1.2 1.2H14M8 17H6.2A1.2 1.2 0 015 15.8V14M7.5 11h7',
  user:     'M11 11a3 3 0 100-6 3 3 0 000 6zM5 18v-.5c0-2.6 2.4-4.2 6-4.2s6 1.6 6 4.2V18',
  clock:    'M11 5.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM11 8v3.2l2.2 1.3',
  check:    'M5 11.5l4 4 8-9',
  chevron:  'M8.5 5l5 6-5 6',
  timeline: 'M7 4.5v13M7 4.5a1.5 1.5 0 100 3 1.5 1.5 0 000-3zm0 13a1.5 1.5 0 100 3 1.5 1.5 0 000-3zM11 6h6M11 11h4M11 16h6',
  snooze:   'M11 5.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM8.6 8.6h3.2l-3.2 4.8h3.2',
  leaf:     'M16 5C9 5 5.5 8.5 5.5 14c0 .9.1 1.7.4 2.5C9 12.5 12.5 10 16.5 9 13 11 9.8 13.5 8 17.5c5.5 1 9.5-2.5 9.5-9 0-1.4-.5-2.6-1.5-3.5z',
  wallet:   'M5 7.5h11a1 1 0 011 1V16a1 1 0 01-1 1H5a1 1 0 01-1-1V7.5zm0 0V6a1 1 0 011-1h8M14.5 11.8a.8.8 0 100 1.6.8.8 0 000-1.6z',
};

// ── Category meta ─────────────────────────────────────────────────────────
const CATEGORIES = {
  Government: { icon: 'gov',      tint: '#74C2A4' },
  Bills:      { icon: 'bill',     tint: '#8FC2D4' },
  Vehicle:    { icon: 'vehicle',  tint: '#90B0D2' },
  Health:     { icon: 'health',   tint: '#78C8AC' },
  Finance:    { icon: 'finance',  tint: '#DCC289' },
  Home:       { icon: 'home',     tint: '#AAB8D4' },
  Family:     { icon: 'family',   tint: '#C2AEE0' },
  Seasonal:   { icon: 'seasonal', tint: '#9CCEDC' },
};

// urgency → emotional color. NEVER pure red.
const URGENCY = {
  urgent: { label: 'Needs you',   color: '#E6A765', glow: 'rgba(230,167,101,0.45)' },
  soon:   { label: 'This week',   color: '#3FD9A4', glow: 'rgba(63,217,164,0.40)' },
  calm:   { label: 'Handled',     color: '#86A6C4', glow: 'rgba(134,166,196,0.30)' },
};

// ── Reminders ─────────────────────────────────────────────────────────────
// progress = fraction of lead-time elapsed (0..1) → drives the ring.
const REMINDERS = [
  {
    id: 'rx', section: 'Today', category: 'Health', urgency: 'urgent', status: 'attention',
    title: 'Prescription refill ready', when: 'Ready today',
    sub: 'Your refill is waiting at Shoppers — Bloor & Spadina.',
    detail: 'Last filled Apr 2 · 1 refill remaining after this one.',
    daysLeft: 0, progress: 0.97, place: 'Pharmacy',
  },
  {
    id: 'hydro', section: 'Today', category: 'Bills', urgency: 'urgent', status: 'urgent',
    title: 'Hydro bill due', when: 'Due in 2 days', amount: '$142.60',
    sub: 'Toronto Hydro auto-pay is off this cycle — pay to avoid a late fee.',
    detail: 'Account ••• 4471 · Pre-authorized payment paused since March.',
    daysLeft: 2, progress: 0.9,
  },
  {
    id: 'ohip', section: 'This Week', category: 'Government', urgency: 'soon', status: 'upcoming',
    title: 'OHIP health card expires', when: 'In 18 days',
    sub: 'Renew online with ServiceOntario — no appointment needed.',
    detail: 'Photo card · Expires Jun 19, 2026. Renewals open up to 6 months early.',
    daysLeft: 18, progress: 0.7,
  },
  {
    id: 'rrsp', section: 'This Week', category: 'Finance', urgency: 'soon', status: 'attention',
    title: 'RRSP top-up window closing', when: 'In 5 days', amount: '$3,200 room',
    sub: 'A little more before the deadline could trim your tax bill.',
    detail: '2025 contribution room remaining · Deadline Mar 2, 2026.',
    daysLeft: 5, progress: 0.85,
  },
  {
    id: 'tires', section: 'This Week', category: 'Vehicle', urgency: 'soon', status: 'info',
    title: 'Book winter-tire swap', when: 'Before the cold snap',
    sub: 'Snow likely this weekend — shops fill up fast once it hits.',
    detail: 'Last swap Nov 12 · Kal Tire usually books 4–5 days out.',
    daysLeft: 6, progress: 0.6,
  },
  {
    id: 'passport', section: 'Upcoming', category: 'Government', urgency: 'calm', status: 'planning',
    title: 'Passport renewal', when: 'In 3 months',
    sub: 'Plenty of time — we’ll remind you before summer travel season.',
    detail: 'Expires Sep 8, 2026 · Allow ~20 business days by mail.',
    daysLeft: 99, progress: 0.3,
  },
  {
    id: 'mortgage', section: 'Upcoming', category: 'Finance', urgency: 'calm', status: 'planning',
    title: 'Mortgage renewal window opens', when: 'Next month',
    sub: 'Worth comparing rates early — we’ll line up the numbers for you.',
    detail: 'Term ends Aug 2026 · Renewal window opens 120 days prior.',
    daysLeft: 34, progress: 0.4,
  },
  {
    id: 'insurance', section: 'Upcoming', category: 'Vehicle', urgency: 'calm', status: 'planning',
    title: 'Auto insurance renewal', when: 'In 6 weeks',
    sub: 'We’ll nudge you in time to shop around before it auto-renews.',
    detail: 'Policy ••• 8830 · Renews Jul 15, 2026.',
    daysLeft: 44, progress: 0.25,
  },
];

// Seasonal "Canadian intelligence" rail
const SEASONAL = [
  { id: 's1', icon: 'finance',  title: 'CRA filing season is open', sub: 'Most returns due Apr 30. Forward your T4 to file early.' },
  { id: 's2', icon: 'leaf',     title: 'Carbon rebate (CCR) deposit', sub: 'Next quarterly payment lands ~Apr 15.' },
  { id: 's3', icon: 'seasonal', title: 'Daylight saving ends soon', sub: 'Clocks back one hour — we’ll shift your morning alerts.' },
  { id: 's4', icon: 'home',     title: 'Property tax — installment 2', sub: 'City of Toronto pre-auth due May 1.' },
];

window.MAPLE = { ICONS, CATEGORIES, URGENCY, REMINDERS, SEASONAL };
})();
