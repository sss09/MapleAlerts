/* MapleAlerts — design tokens: depth surfaces, semantic colors, cooler aurora */

const { ICONS } = window.MAPLE;

// ── Cool neutral foundation (icy slate / blue-steel, low saturation) ───────
const C = {
  bg:    '#070d15',   // canvas — very dark navy
  s1:    '#0b1320',   // secondary surface — blue-black
  s2:    '#101d26',   // card base — slight teal tint
  line:  'rgba(156,178,200,0.10)',
  lineStrong: 'rgba(156,178,200,0.18)',
  slate: '#8A99AC',   // muted slate — completed / passive
};
const TEXT  = '#E6EDF3';                    // cool soft white
const MUTED = 'rgba(180,196,212,0.62)';
const FAINT = 'rgba(180,196,212,0.38)';
const GREEN = '#5BC6A0';                    // atmospheric aurora green (cooler, softer)
const GREEN_HI = '#62D2A8';

// ── Semantic color intelligence ───────────────────────────────────────────
// Emerald=upcoming · Cyan=info · Amber=attention · Soft-red=urgent · Purple=planning · Slate=done
const SEM = {
  urgent:    { color: '#E78B7B', edge: 'rgba(231,139,123,0.55)', glow: 'rgba(231,139,123,0.30)', soft: 'rgba(231,139,123,0.13)', label: 'Urgent' },
  attention: { color: '#E4B469', edge: 'rgba(228,180,105,0.55)', glow: 'rgba(228,180,105,0.26)', soft: 'rgba(228,180,105,0.12)', label: 'Needs attention' },
  upcoming:  { color: '#5FC6A0', edge: 'rgba(95,198,160,0.50)',  glow: 'rgba(95,198,160,0.24)',  soft: 'rgba(95,198,160,0.11)',  label: 'Upcoming' },
  info:      { color: '#71C3D6', edge: 'rgba(113,195,214,0.50)', glow: 'rgba(113,195,214,0.24)', soft: 'rgba(113,195,214,0.11)', label: 'Good to know' },
  planning:  { color: '#A79CE2', edge: 'rgba(167,156,226,0.46)', glow: 'rgba(167,156,226,0.22)', soft: 'rgba(167,156,226,0.11)', label: 'Planning ahead' },
  done:      { color: '#8A99AC', edge: 'rgba(138,153,172,0.35)', glow: 'rgba(138,153,172,0.16)', soft: 'rgba(138,153,172,0.10)', label: 'Handled' },
};

// ── Aurora gradient systems — softer, foggier, less saturated ─────────────
const AURORAS = {
  emerald: {
    label: 'Aurora Fog',
    base: 'radial-gradient(130% 95% at 50% -12%, #143029 0%, #0b1a26 48%, #070e16 100%)',
    blobs: [
      { c: 'rgba(74,176,140,0.30)', s: 420, x: '6%',  y: '4%'  },
      { c: 'rgba(52,116,128,0.26)', s: 460, x: '80%', y: '0%'  },
      { c: 'rgba(58,96,142,0.22)',  s: 480, x: '58%', y: '64%' },
    ],
  },
  teal: {
    label: 'Teal Frost',
    base: 'radial-gradient(130% 95% at 50% -12%, #103a3a 0%, #0a2230 48%, #060c14 100%)',
    blobs: [
      { c: 'rgba(58,186,168,0.30)', s: 420, x: '10%', y: '2%'  },
      { c: 'rgba(40,128,140,0.26)', s: 450, x: '82%', y: '6%'  },
      { c: 'rgba(48,104,150,0.22)', s: 470, x: '52%', y: '62%' },
    ],
  },
  arctic: {
    label: 'Arctic Steel',
    base: 'radial-gradient(130% 95% at 50% -12%, #15324e 0%, #0c2036 48%, #060d18 100%)',
    blobs: [
      { c: 'rgba(74,148,200,0.28)', s: 420, x: '8%',  y: '4%'  },
      { c: 'rgba(86,116,190,0.24)', s: 450, x: '82%', y: '2%'  },
      { c: 'rgba(52,150,160,0.22)', s: 450, x: '58%', y: '66%' },
    ],
  },
  lights: {
    label: 'Northern Lights',
    base: 'radial-gradient(130% 95% at 50% -12%, #133436 0%, #0b1f2e 46%, #080d1a 100%)',
    blobs: [
      { c: 'rgba(70,184,150,0.28)', s: 420, x: '4%',  y: '6%'  },
      { c: 'rgba(126,108,196,0.22)', s: 450, x: '84%', y: '4%' },
      { c: 'rgba(48,150,156,0.22)', s: 440, x: '54%', y: '60%' },
    ],
  },
};

// ── Atmospheric aurora layer (snow-fog, not glow-dashboard) ────────────────
function Aurora({ system = 'emerald', motion = true }) {
  const a = AURORAS[system] || AURORAS.emerald;
  return (
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', background: a.base, zIndex: 0 }}>
      {a.blobs.map((b, i) => (
        <div key={i} style={{
          position: 'absolute', left: b.x, top: b.y, width: b.s, height: b.s, borderRadius: '50%',
          background: `radial-gradient(circle, ${b.c} 0%, transparent 70%)`, filter: 'blur(40px)',
          animation: motion ? `auroraDrift${i % 3} ${24 + i * 7}s ease-in-out infinite alternate` : 'none',
          willChange: 'transform',
        }} />
      ))}
      {/* snow-fog veil — desaturates + adds atmospheric depth */}
      <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(180deg, rgba(8,14,22,0.10) 0%, rgba(7,12,20,0.30) 55%, rgba(6,11,18,0.62) 100%)' }} />
      <div style={{ position: 'absolute', inset: 0, background: 'rgba(12,20,30,0.16)' }} />
      {/* fine grain to kill banding */}
      <div style={{
        position: 'absolute', inset: 0, opacity: 0.4, mixBlendMode: 'overlay',
        backgroundImage: 'url("data:image/svg+xml;utf8,<svg xmlns=\'http://www.w3.org/2000/svg\' width=\'80\' height=\'80\'><filter id=\'n\'><feTurbulence type=\'fractalNoise\' baseFrequency=\'0.9\' numOctaves=\'2\'/></filter><rect width=\'80\' height=\'80\' filter=\'url(%23n)\' opacity=\'0.55\'/></svg>")',
      }} />
    </div>
  );
}

// ── Icon ──────────────────────────────────────────────────────────────────
function Icon({ name, size = 20, color = 'currentColor', sw = 1.7, style }) {
  const d = ICONS[name];
  if (!d) return null;
  return (
    <svg width={size} height={size} viewBox="0 0 22 22" fill="none" style={style}>
      <path d={d} stroke={color} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

// ── Progress ring ─────────────────────────────────────────────────────────
function Ring({ progress = 0.5, size = 38, sw = 3, color = GREEN, track = 'rgba(156,178,200,0.14)', glow = true, children }) {
  const r = (size - sw) / 2, c = 2 * Math.PI * r;
  return (
    <div style={{ position: 'relative', width: size, height: size, flexShrink: 0 }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size / 2} cy={size / 2} r={r} stroke={track} strokeWidth={sw} fill="none" />
        <circle cx={size / 2} cy={size / 2} r={r} stroke={color} strokeWidth={sw} fill="none"
          strokeLinecap="round" strokeDasharray={c} strokeDashoffset={c * (1 - progress)}
          style={{ transition: 'stroke-dashoffset 0.8s cubic-bezier(.4,0,.2,1)', filter: glow ? `drop-shadow(0 0 4px ${color}55)` : 'none' }} />
      </svg>
      {children && <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{children}</div>}
    </div>
  );
}

// ── Surface system — matte, depth-aware, status-reactive ───────────────────
// level: 'minimal' | 'bordered' | 'solid' (card elevation, mostly matte)
// opts: { status, active, passive, ...cssExtra }
function surface(level = 'minimal', opts = {}) {
  const { status, active, passive, ...extra } = opts;
  const sem = status ? SEM[status] : null;
  let b = {
    minimal:  { bg: 'rgba(17,30,40,0.55)',  bd: C.line,        blur: 'blur(9px)'  },
    bordered: { bg: 'rgba(13,24,34,0.42)',  bd: C.lineStrong,  blur: 'blur(7px)'  },
    solid:    { bg: 'rgba(22,35,46,0.72)',  bd: C.line,        blur: 'blur(12px)' },
  }[level] || { bg: 'rgba(17,30,40,0.55)', bd: C.line, blur: 'blur(9px)' };
  if (passive) b = { bg: 'rgba(13,20,29,0.42)', bd: 'rgba(138,153,172,0.10)', blur: 'blur(6px)' };
  return {
    background: b.bg,
    border: `1px solid ${active && sem ? sem.edge : b.bd}`,
    backdropFilter: b.blur, WebkitBackdropFilter: b.blur,
    boxShadow: active && sem
      ? `0 0 26px ${sem.glow}, inset 0 0 0 1px ${sem.soft}, 0 12px 30px rgba(0,0,0,0.40)`
      : '0 8px 22px rgba(0,0,0,0.30), inset 0 1px 0 rgba(255,255,255,0.03)',
    ...extra,
  };
}

// Back-compat alias — older calls used glass(); now matte by default.
const glass = surface;

Object.assign(window, { C, SEM, AURORAS, Aurora, Icon, Ring, surface, glass, TEXT, MUTED, FAINT, GREEN, GREEN_HI });
