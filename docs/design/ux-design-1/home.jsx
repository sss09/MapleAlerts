/* MapleAlerts — Home: hero, sections, weighted semantic reminder cards */

const { CATEGORIES, REMINDERS, SEASONAL } = window.MAPLE;

// semantic status → color. Calm mode (warm accents off) cools the hot statuses.
function statusColor(item, t) {
  const s = item.status;
  if (!t.mapleAccent && (s === 'urgent' || s === 'attention')) return '#8FA8C0';
  return window.SEM[s].color;
}

// ── Reminder card: swipe-to-act + tap-to-expand, weight follows status ─────
function ReminderCard({ item, t, onDone, onSnooze }) {
  const [open, setOpen] = React.useState(false);
  const [dx, setDx] = React.useState(0);
  const [gone, setGone] = React.useState(false);
  const drag = React.useRef(null);
  const cat = CATEGORIES[item.category];
  const sem = window.SEM[item.status];
  const uc = statusColor(item, t);
  const pop = item.status === 'urgent' || item.status === 'attention';
  const passive = item.status === 'planning';
  const REVEAL = -150;

  const down = (e) => { drag.current = { x: e.clientX, dx0: dx, moved: false }; };
  const move = (e) => {
    if (!drag.current) return;
    let nd = drag.current.dx0 + (e.clientX - drag.current.x);
    nd = Math.max(REVEAL - 30, Math.min(0, nd));
    if (Math.abs(e.clientX - drag.current.x) > 4) drag.current.moved = true;
    setDx(nd);
  };
  const up = () => { if (!drag.current) return; setDx(dx < REVEAL * 0.5 ? REVEAL : 0); setTimeout(() => { drag.current = null; }, 0); };
  const tap = () => { if (!drag.current || !drag.current.moved) { if (dx !== 0) setDx(0); else setOpen(o => !o); } };
  const finishDone = () => { setGone(true); setTimeout(() => onDone(item.id), 360); };
  const finishSnooze = () => { setDx(0); onSnooze(item.id); };

  return (
    <div style={{
      position: 'relative', marginBottom: 12,
      maxHeight: gone ? 0 : 400, opacity: gone ? 0 : 1, transform: gone ? 'scale(0.92)' : 'scale(1)',
      transition: 'max-height .36s cubic-bezier(.4,0,.2,1), opacity .3s, transform .36s, margin .36s', overflow: 'hidden',
    }}>
      {/* swipe action layer */}
      <div style={{ position: 'absolute', inset: 0, borderRadius: 22, display: 'flex', justifyContent: 'flex-end', gap: 8, padding: 6 }}>
        <button onClick={finishSnooze} style={actionBtn('rgba(138,153,172,0.18)', '#c3d2e2')}>
          <Icon name="snooze" size={20} color="#cdd9e6" /><span style={actLbl}>Snooze</span>
        </button>
        <button onClick={finishDone} style={actionBtn('rgba(91,198,160,0.20)', GREEN)}>
          <Icon name="check" size={20} color={GREEN_HI} sw={2} /><span style={actLbl}>Done</span>
        </button>
      </div>

      {/* card face */}
      <div
        onPointerDown={down} onPointerMove={move} onPointerUp={up} onPointerLeave={up} onClick={tap}
        style={{
          ...surface(t.cardStyle, { status: item.status, active: open || pop, passive, borderRadius: 22, padding: '15px 15px 15px 14px' }),
          position: 'relative', transform: `translateX(${dx}px)`,
          transition: drag.current ? 'none' : 'transform .42s cubic-bezier(.22,1,.36,1)',
          cursor: 'pointer', touchAction: 'pan-y',
        }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 13 }}>
          <Ring progress={item.progress} size={42} sw={3} color={uc} glow={!passive}>
            <div style={{ width: 30, height: 30, borderRadius: '50%', background: 'rgba(156,178,200,0.07)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name={cat.icon} size={17} color={passive ? C.slate : cat.tint} sw={1.7} />
            </div>
          </Ring>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
              <div style={{ color: passive ? 'rgba(214,224,234,0.82)' : TEXT, fontSize: 15.5, fontWeight: 600, letterSpacing: '-0.01em', flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.title}</div>
              {item.amount && <div style={{ color: TEXT, fontSize: 13, fontWeight: 600, fontVariantNumeric: 'tabular-nums', opacity: 0.82 }}>{item.amount}</div>}
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginTop: 4 }}>
              <span style={{ width: 6, height: 6, borderRadius: 6, background: uc, boxShadow: passive ? 'none' : `0 0 6px ${uc}` }} />
              <span style={{ fontSize: 11.5, fontWeight: 600, color: uc, letterSpacing: '0.01em' }}>{item.when}</span>
              <span style={{ width: 3, height: 3, borderRadius: 3, background: FAINT }} />
              <span style={{ fontSize: 11.5, color: FAINT }}>{item.category}</span>
            </div>
          </div>
          <Icon name="chevron" size={16} color={FAINT} style={{ transform: open ? 'rotate(90deg)' : 'none', transition: 'transform .3s', marginLeft: 2 }} />
        </div>

        {/* expandable detail */}
        <div style={{ maxHeight: open ? 220 : 0, opacity: open ? 1 : 0, overflow: 'hidden', transition: 'max-height .4s cubic-bezier(.4,0,.2,1), opacity .35s' }}>
          <div style={{ paddingTop: 13, marginTop: 13, borderTop: '1px solid rgba(156,178,200,0.10)' }}>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 5, padding: '3px 9px', borderRadius: 8, background: sem.soft, marginBottom: 10 }}>
              <span style={{ width: 6, height: 6, borderRadius: 6, background: uc }} />
              <span style={{ fontSize: 10.5, fontWeight: 700, letterSpacing: '0.03em', color: uc }}>{sem.label}</span>
            </div>
            <p style={{ margin: 0, fontSize: 13.5, lineHeight: 1.5, color: 'rgba(214,224,234,0.78)' }}>{item.sub}</p>
            <p style={{ margin: '8px 0 0', fontSize: 12, lineHeight: 1.5, color: FAINT }}>{item.detail}</p>
            <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
              <button onClick={(e) => { e.stopPropagation(); finishDone(); }} style={pillBtn(uc, true)}>Mark done</button>
              <button onClick={(e) => { e.stopPropagation(); finishSnooze(); }} style={pillBtn('', false)}>Snooze</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

const actLbl = { fontSize: 10.5, fontWeight: 600, marginTop: 3, letterSpacing: '0.01em' };
function actionBtn(bg, col) {
  return { width: 66, border: 'none', borderRadius: 18, background: bg, color: col, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' };
}
function pillBtn(col, solid) {
  return { flex: 1, height: 38, borderRadius: 12, border: 'none', cursor: 'pointer', fontSize: 13, fontWeight: 600, letterSpacing: '-0.01em',
    background: solid ? col : 'rgba(156,178,200,0.08)', color: solid ? '#06231c' : TEXT,
    boxShadow: solid ? `0 6px 16px ${col}3a` : 'none' };
}

// ── Section header ────────────────────────────────────────────────────────
function SectionHeader({ label, count }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 9, margin: '22px 4px 13px' }}>
      <h2 style={{ margin: 0, fontSize: 19, fontWeight: 700, color: TEXT, letterSpacing: '-0.02em' }}>{label}</h2>
      <span style={{ fontSize: 12.5, color: FAINT, fontVariantNumeric: 'tabular-nums' }}>{count}</span>
    </div>
  );
}

// ── Hero summary ──────────────────────────────────────────────────────────
function Hero({ t, needs, total }) {
  const handled = total - needs;
  return (
    <div style={{ ...surface(t.cardStyle, { borderRadius: 26, padding: 18, marginTop: 4 }) }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
        <Ring progress={total ? handled / total : 1} size={66} sw={5} color={GREEN}>
          <div style={{ textAlign: 'center', lineHeight: 1 }}>
            <div style={{ fontSize: 19, fontWeight: 700, color: TEXT, fontVariantNumeric: 'tabular-nums' }}>{needs}</div>
            <div style={{ fontSize: 8.5, color: FAINT, marginTop: 1 }}>to do</div>
          </div>
        </Ring>
        <div style={{ flex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 5 }}>
            <Icon name="sparkle" size={14} color={GREEN} />
            <span style={{ fontSize: 10.5, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: GREEN }}>Your day, handled</span>
          </div>
          <p style={{ margin: 0, fontSize: 15, lineHeight: 1.45, color: TEXT, fontWeight: 500, textWrap: 'pretty' }}>
            <b style={{ fontWeight: 700 }}>{needs} things</b> need you this week. The other {handled} are quietly taken care of.
          </p>
        </div>
      </div>
    </div>
  );
}

// ── Semantic colour legend ────────────────────────────────────────────────
function Legend() {
  const keys = ['urgent', 'attention', 'upcoming', 'info', 'planning'];
  return (
    <div style={{ display: 'flex', gap: 7, overflowX: 'auto', margin: '14px -20px 0', padding: '0 20px', scrollbarWidth: 'none' }}>
      {keys.map(k => {
        const s = window.SEM[k];
        return (
          <div key={k} style={{ flexShrink: 0, display: 'flex', alignItems: 'center', gap: 6, height: 26, padding: '0 10px', borderRadius: 13, background: s.soft, border: `1px solid ${s.color}26` }}>
            <span style={{ width: 6, height: 6, borderRadius: 6, background: s.color, boxShadow: `0 0 5px ${s.color}` }} />
            <span style={{ fontSize: 10.5, fontWeight: 600, color: s.color, letterSpacing: '0.01em', whiteSpace: 'nowrap' }}>{s.label}</span>
          </div>
        );
      })}
    </div>
  );
}

// ── Category filter chips ─────────────────────────────────────────────────
function Chips({ active, onPick }) {
  const cats = ['All', ...Object.keys(CATEGORIES)];
  return (
    <div style={{ display: 'flex', gap: 8, overflowX: 'auto', padding: '2px 20px', margin: '18px -20px 0', scrollbarWidth: 'none' }}>
      {cats.map(c => {
        const on = active === c;
        const tint = c === 'All' ? GREEN : CATEGORIES[c].tint;
        return (
          <button key={c} onClick={() => onPick(c)} style={{
            flexShrink: 0, height: 34, padding: '0 14px', borderRadius: 17, cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 6,
            border: on ? `1px solid ${tint}5a` : `1px solid ${C.lineStrong}`,
            background: on ? `${tint}1e` : 'rgba(23,36,48,0.62)',
            color: on ? tint : 'rgba(200,214,228,0.72)', fontSize: 13, fontWeight: 600, letterSpacing: '-0.01em', transition: 'all .25s',
          }}>
            {c !== 'All' && <Icon name={CATEGORIES[c].icon} size={14} color={on ? tint : MUTED} sw={1.7} />}
            {c}
          </button>
        );
      })}
    </div>
  );
}

// ── Seasonal rail ─────────────────────────────────────────────────────────
function SeasonalRail() {
  return (
    <div>
      <SectionHeader label="Seasonal — Canada" count="this month" />
      <div style={{ display: 'flex', gap: 12, overflowX: 'auto', margin: '0 -20px', padding: '2px 20px 4px', scrollbarWidth: 'none' }}>
        {SEASONAL.map(s => (
          <div key={s.id} style={{ ...surface('bordered', { borderRadius: 20, padding: 15 }), flexShrink: 0, width: 192 }}>
            <div style={{ width: 34, height: 34, borderRadius: 11, background: 'rgba(113,195,214,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 11 }}>
              <Icon name={s.icon} size={18} color="#71C3D6" />
            </div>
            <div style={{ fontSize: 14, fontWeight: 650, color: TEXT, lineHeight: 1.25, letterSpacing: '-0.01em' }}>{s.title}</div>
            <div style={{ fontSize: 11.5, color: MUTED, lineHeight: 1.4, marginTop: 6, textWrap: 'pretty' }}>{s.sub}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Home screen ───────────────────────────────────────────────────────────
function HomeScreen({ t, onScroll }) {
  const [filter, setFilter] = React.useState('All');
  const [done, setDone] = React.useState({});
  const [, setSnoozed] = React.useState({});
  const visible = REMINDERS.filter(r => !done[r.id] && (filter === 'All' || r.category === filter));
  const needs = REMINDERS.filter(r => !done[r.id] && (r.status === 'urgent' || r.status === 'attention')).length;
  const sections = ['Today', 'This Week', 'Upcoming'];
  const markDone = (id) => setDone(d => ({ ...d, [id]: true }));
  const snooze = (id) => setSnoozed(s => ({ ...s, [id]: true }));

  return (
    <div onScroll={(e) => onScroll(e.target.scrollTop)} style={{
      position: 'absolute', inset: 0, overflowY: 'auto', overflowX: 'hidden',
      padding: '60px 20px 130px', scrollbarWidth: 'none', WebkitOverflowScrolling: 'touch',
    }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 24 }}>
        <div>
          <div style={{ fontSize: 12.5, fontWeight: 600, color: GREEN, letterSpacing: '0.02em' }}>Good evening, Maya</div>
          <div style={{ fontSize: 27, fontWeight: 700, color: TEXT, letterSpacing: '-0.03em', marginTop: 3, lineHeight: 1.05 }}>Tuesday, Feb 24</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, height: 32, padding: '0 11px', borderRadius: 16, ...surface('bordered'), marginTop: 4 }}>
          <Icon name="seasonal" size={14} color="#9CCEDC" />
          <span style={{ fontSize: 12.5, fontWeight: 600, color: TEXT, fontVariantNumeric: 'tabular-nums' }}>−8°</span>
          <span style={{ fontSize: 11, color: MUTED }}>Snow</span>
        </div>
      </div>

      <Hero t={t} needs={needs} total={REMINDERS.filter(r => !done[r.id]).length} />
      <Chips active={filter} onPick={setFilter} />
      {t.legend && <Legend />}

      {sections.map(sec => {
        const items = visible.filter(r => r.section === sec);
        if (!items.length) return null;
        return (
          <div key={sec}>
            <SectionHeader label={sec} count={`${items.length} item${items.length > 1 ? 's' : ''}`} />
            {items.map(it => <ReminderCard key={it.id} item={it} t={t} onDone={markDone} onSnooze={snooze} />)}
          </div>
        );
      })}

      <div style={{ marginTop: 8 }}><SeasonalRail /></div>

      <div style={{ textAlign: 'center', marginTop: 26, fontSize: 11.5, color: FAINT, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>
        <Icon name="check" size={13} color={FAINT} /> You’re all caught up
      </div>
    </div>
  );
}

Object.assign(window, { HomeScreen, ReminderCard });
