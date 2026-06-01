/* MapleAlerts — app shell: nav, FAB, tweaks, mount */

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "aurora": "emerald",
  "cardStyle": "minimal",
  "fab": "dock",
  "mapleAccent": true,
  "legend": true,
  "motion": true
}/*EDITMODE-END*/;

const TABS = [
  { id: 'Home',     icon: 'home',     label: 'Home' },
  { id: 'Timeline', icon: 'timeline', label: 'Timeline' },
  { id: 'Alerts',   icon: 'bell',     label: 'Alerts' },
  { id: 'Profile',  icon: 'user',     label: 'You' },
];

// ── Floating action button (3 behaviors) ──────────────────────────────────
function Fab({ mode, onAdd }) {
  const [radialOpen, setRadialOpen] = React.useState(false);
  const press = () => { if (mode === 'radial') setRadialOpen(o => !o); else onAdd(); };
  const pick = () => { setRadialOpen(false); onAdd(); };

  const core = (
    <button onClick={press} style={{
      width: 60, height: 60, borderRadius: '50%', border: 'none', cursor: 'pointer',
      background: 'linear-gradient(155deg,#62D2A8,#3CA07E)', position: 'relative', zIndex: 2,
      boxShadow: '0 10px 26px rgba(91,198,160,0.42), inset 0 1px 0 rgba(255,255,255,0.35)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      transition: 'transform .3s cubic-bezier(.22,1,.36,1)',
      transform: radialOpen ? 'rotate(135deg)' : 'none',
    }}>
      <Icon name="plus" size={26} color="#06231c" sw={2.4} />
    </button>
  );

  const radials = [
    { icon: 'mic', a: -150 }, { icon: 'sparkle', a: -90 }, { icon: 'scan', a: -30 },
  ];

  const wrap = (children, pos) => (
    <div style={{ position: 'absolute', zIndex: 70, ...pos }}>
      {mode === 'radial' && radials.map((r, i) => {
        const rad = r.a * Math.PI / 180, dist = radialOpen ? 76 : 0;
        return (
          <button key={i} onClick={pick} style={{
            position: 'absolute', left: 6, top: 6, width: 48, height: 48, borderRadius: '50%', border: 'none', cursor: 'pointer',
            background: 'rgba(15,26,36,0.94)', backdropFilter: 'blur(10px)', border: '1px solid rgba(91,198,160,0.3)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            transform: `translate(${Math.cos(rad) * dist}px, ${Math.sin(rad) * dist}px)`,
            opacity: radialOpen ? 1 : 0, transition: `all .42s cubic-bezier(.22,1,.36,1) ${i * 0.04}s`,
            boxShadow: '0 8px 20px rgba(0,0,0,0.4)',
          }}><Icon name={r.icon} size={20} color={GREEN_HI} /></button>
        );
      })}
      {children}
    </div>
  );

  if (mode === 'float') return wrap(core, { right: 18, bottom: 104 });
  // dock + radial → centered, raised over the tab bar
  return wrap(core, { left: '50%', bottom: 30, transform: 'translateX(-50%)' });
}

// ── Bottom tab bar ────────────────────────────────────────────────────────
function TabBar({ tab, setTab, fab, onAdd }) {
  const gap = fab !== 'float';
  const left = TABS.slice(0, 2), right = TABS.slice(2);
  const item = (tb) => {
    const on = tab === tb.id;
    return (
      <button key={tb.id} onClick={() => setTab(tb.id)} style={{
        flex: 1, background: 'none', border: 'none', cursor: 'pointer', padding: '6px 0',
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
        color: on ? GREEN_HI : 'rgba(190,204,218,0.5)', transition: 'color .25s',
      }}>
        <Icon name={tb.icon} size={22} color={on ? GREEN_HI : 'rgba(190,204,218,0.5)'} sw={on ? 2 : 1.7} />
        <span style={{ fontSize: 9.5, fontWeight: on ? 700 : 500, letterSpacing: '0.01em' }}>{tb.label}</span>
      </button>
    );
  };
  return (
    <div style={{
      position: 'absolute', left: 14, right: 14, bottom: 16, zIndex: 60, height: 66,
      borderRadius: 26, display: 'flex', alignItems: 'center', padding: '0 6px',
      background: 'rgba(11,19,30,0.66)', backdropFilter: 'blur(26px) saturate(150%)', WebkitBackdropFilter: 'blur(26px) saturate(150%)',
      border: '1px solid rgba(156,178,200,0.12)', boxShadow: '0 14px 40px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.05)',
    }}>
      {left.map(item)}
      {gap && <div style={{ width: 64, flexShrink: 0 }} />}
      {right.map(item)}
      {fab === 'float' && (
        <button onClick={onAdd} style={{ flexShrink: 0, width: 40 }} />
      )}
    </div>
  );
}

// ── Aurora system swatch picker (custom tweak control) ────────────────────
function AuroraSwatches({ value, onChange }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, padding: '4px 0 2px' }}>
      {Object.entries(AURORAS).map(([k, a]) => {
        const on = value === k;
        return (
          <button key={k} onClick={() => onChange(k)} style={{
            border: on ? `2px solid ${GREEN}` : '2px solid rgba(156,178,200,0.14)', borderRadius: 12, padding: 0, cursor: 'pointer', overflow: 'hidden', height: 52, position: 'relative', background: a.base,
          }}>
            <span style={{ position: 'absolute', left: 0, right: 0, bottom: 0, padding: '3px 6px', fontSize: 9.5, fontWeight: 600, color: '#fff', textAlign: 'left', background: 'linear-gradient(0deg,rgba(0,0,0,0.55),transparent)' }}>{a.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// ── App ───────────────────────────────────────────────────────────────────
function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [tab, setTab] = React.useState('Home');
  const [scroll, setScroll] = React.useState(0);
  const [adding, setAdding] = React.useState(false);

  const screens = {
    Home: <HomeScreen t={t} onScroll={setScroll} />,
    Timeline: <TimelineScreen t={t} />,
    Alerts: <AlertsScreen />,
    Profile: <ProfileScreen />,
  };

  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '100vh', padding: 24, boxSizing: 'border-box' }}>
      <IOSDevice dark width={402} height={874}>
        <div style={{ position: 'relative', height: '100%', overflow: 'hidden', background: '#060c14' }}>
          {/* aurora with gentle parallax on scroll */}
          <div style={{ position: 'absolute', inset: 0, transform: `translateY(${tab === 'Home' ? -scroll * 0.05 : 0}px) scale(1.06)`, transition: 'transform .1s linear', zIndex: 0 }}>
            <Aurora system={t.aurora} motion={t.motion} />
          </div>
          {/* top fade so status bar reads */}
          <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 110, background: 'linear-gradient(180deg,rgba(6,12,20,0.8),transparent)', zIndex: 1, pointerEvents: 'none' }} />

          {/* active screen — base opacity stays 1 so content never depends on
              a one-shot animation advancing (capture iframes can stall those) */}
          <div key={tab} style={{ position: 'absolute', inset: 0, zIndex: 2, opacity: 1, animation: t.motion ? 'screenIn .5s cubic-bezier(.22,1,.36,1)' : 'none' }}>
            {screens[tab]}
          </div>

          <TabBar tab={tab} setTab={setTab} fab={t.fab} onAdd={() => setAdding(true)} />
          <Fab mode={t.fab} onAdd={() => setAdding(true)} />
          <AddSheet open={adding} onClose={() => setAdding(false)} />
        </div>
      </IOSDevice>

      <TweaksPanel>
        <TweakSection label="Aurora system" />
        <AuroraSwatches value={t.aurora} onChange={(v) => setTweak('aurora', v)} />
        <TweakSection label="Surfaces" />
        <TweakRadio label="Card style" value={t.cardStyle} options={['minimal', 'bordered', 'solid']} onChange={(v) => setTweak('cardStyle', v)} />
        <TweakSection label="Add button" />
        <TweakRadio label="FAB behavior" value={t.fab} options={['dock', 'float', 'radial']} onChange={(v) => setTweak('fab', v)} />
        <TweakSection label="Feel" />
        <TweakToggle label="Warm urgency accents" value={t.mapleAccent} onChange={(v) => setTweak('mapleAccent', v)} />
        <TweakToggle label="Status colour legend" value={t.legend} onChange={(v) => setTweak('legend', v)} />
        <TweakToggle label="Ambient motion" value={t.motion} onChange={(v) => setTweak('motion', v)} />
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
