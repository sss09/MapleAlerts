/* MapleAlerts — Add sheet, Alerts preview, Timeline & Profile screens */

const { CATEGORIES: CATS, REMINDERS: REMS } = window.MAPLE;

// ── Natural-language → smart categorization (lightweight) ─────────────────
const RULES = [
  { k: ['passport'],            cat: 'Government', when: 'Sep 2026' },
  { k: ['health card', 'ohip'], cat: 'Government', when: 'in 18 days' },
  { k: ['snow tire', 'winter tire', 'tires'], cat: 'Vehicle', when: 'by Nov 1' },
  { k: ['insurance'],           cat: 'Vehicle',    when: 'at renewal' },
  { k: ['sticker', 'licence', 'license', 'plate'], cat: 'Vehicle', when: 'on your birthday' },
  { k: ['property tax', 'tax'], cat: 'Finance',    when: 'quarterly' },
  { k: ['rrsp', 'tfsa', 'contribution'], cat: 'Finance', when: 'by Mar 1' },
  { k: ['mortgage'],            cat: 'Finance',    when: 'at term end' },
  { k: ['hydro', 'bill', 'rent', 'utility'], cat: 'Bills', when: 'monthly' },
  { k: ['prescription', 'refill', 'doctor', 'dentist'], cat: 'Health', when: 'when ready' },
  { k: ['school', 'kids', 'daycare'], cat: 'Family', when: 'in September' },
];
function detect(text) {
  const low = text.toLowerCase();
  for (const r of RULES) if (r.k.some(w => low.includes(w))) return r;
  return null;
}
const SUGGEST = ['Renew passport in September', 'Snow tires by November', 'Pay property tax quarterly', 'RRSP top-up before March 1'];

// ── Add reminder bottom sheet ─────────────────────────────────────────────
function AddSheet({ open, onClose }) {
  const [text, setText] = React.useState('');
  const [mounted, setMounted] = React.useState(false);
  const hit = detect(text);
  React.useEffect(() => { if (open) { setMounted(true); setText(''); } }, [open]);
  if (!mounted && !open) return null;

  const methods = [{ icon: 'mic', label: 'Voice' }, { icon: 'scan', label: 'Scan letter' }, { icon: 'bell', label: 'Forward email' }];

  return (
    <div onTransitionEnd={() => { if (!open) setMounted(false); }}
      style={{ position: 'absolute', inset: 0, zIndex: 80, pointerEvents: open ? 'auto' : 'none' }}>
      <div onClick={onClose} style={{ position: 'absolute', inset: 0, background: 'rgba(4,9,15,0.6)', backdropFilter: 'blur(3px)', opacity: open ? 1 : 0, transition: 'opacity .4s' }} />
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        transform: open ? 'translateY(0)' : 'translateY(105%)', transition: 'transform .5s cubic-bezier(.22,1,.36,1)',
        borderTopLeftRadius: 30, borderTopRightRadius: 30, padding: '12px 20px 30px',
        background: 'rgba(13,22,31,0.94)', backdropFilter: 'blur(30px)', WebkitBackdropFilter: 'blur(30px)',
        borderTop: '1px solid rgba(156,178,200,0.14)', boxShadow: '0 -20px 60px rgba(0,0,0,0.55)',
      }}>
        <div style={{ width: 38, height: 5, borderRadius: 3, background: 'rgba(156,178,200,0.24)', margin: '0 auto 16px' }} />
        <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginBottom: 14 }}>
          <Icon name="sparkle" size={16} color={GREEN} />
          <span style={{ fontSize: 13, fontWeight: 700, color: TEXT }}>Add anything — we’ll sort it out</span>
        </div>

        <div style={{ ...surface('solid', { borderRadius: 18, padding: '14px 16px' }) }}>
          <textarea autoFocus value={text} onChange={e => setText(e.target.value)} rows={2}
            placeholder="“Renew my passport in September…”"
            style={{ width: '100%', border: 'none', background: 'transparent', resize: 'none', outline: 'none', color: TEXT, fontSize: 16, lineHeight: 1.4, fontFamily: 'inherit' }} />
        </div>

        <div style={{ maxHeight: hit ? 70 : 0, opacity: hit ? 1 : 0, overflow: 'hidden', transition: 'all .4s cubic-bezier(.4,0,.2,1)' }}>
          {hit && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 12, padding: '11px 13px', borderRadius: 14, background: `${CATS[hit.cat].tint}18`, border: `1px solid ${CATS[hit.cat].tint}33` }}>
              <div style={{ width: 30, height: 30, borderRadius: 9, background: `${CATS[hit.cat].tint}20`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name={CATS[hit.cat].icon} size={16} color={CATS[hit.cat].tint} />
              </div>
              <div style={{ fontSize: 12.5, color: TEXT, lineHeight: 1.35 }}>
                Filed under <b style={{ color: CATS[hit.cat].tint }}>{hit.cat}</b> · I’ll remind you <b>{hit.when}</b>.
              </div>
            </div>
          )}
        </div>

        {!text && (
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 14 }}>
            {SUGGEST.map(s => (
              <button key={s} onClick={() => setText(s)} style={{ padding: '8px 12px', borderRadius: 13, border: `1px solid ${C.line}`, background: 'rgba(17,30,40,0.5)', color: MUTED, fontSize: 12.5, cursor: 'pointer', fontWeight: 500 }}>{s}</button>
            ))}
          </div>
        )}

        <div style={{ display: 'flex', gap: 9, marginTop: 16 }}>
          {methods.map(m => (
            <button key={m.label} style={{ flex: 1, height: 58, borderRadius: 16, border: `1px solid ${C.line}`, background: 'rgba(17,30,40,0.45)', color: MUTED, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 5, cursor: 'pointer' }}>
              <Icon name={m.icon} size={19} color="#9CCEDC" />
              <span style={{ fontSize: 10.5, fontWeight: 600 }}>{m.label}</span>
            </button>
          ))}
        </div>

        <button onClick={onClose} style={{ width: '100%', height: 52, marginTop: 16, borderRadius: 17, border: 'none', cursor: 'pointer',
          background: text ? GREEN : 'rgba(156,178,200,0.08)', color: text ? '#06231c' : FAINT, fontSize: 15.5, fontWeight: 700, letterSpacing: '-0.01em',
          boxShadow: text ? '0 10px 24px rgba(91,198,160,0.26)' : 'none', transition: 'all .3s' }}>
          {text ? 'Add reminder' : 'Type something to begin'}
        </button>
      </div>
    </div>
  );
}

// ── Alerts (notification experience) ──────────────────────────────────────
const NOTES = [
  { cat: 'Finance', st: 'planning',  title: 'A gentle heads-up', body: 'Your mortgage renewal window opens next month. Want me to pull current rates so you can compare?', time: 'now' },
  { cat: 'Vehicle', st: 'info',      title: 'Winter’s coming', body: 'Looks like snow-tire season is approaching. Most shops near you book 4–5 days out.', time: '2h ago' },
  { cat: 'Government', st: 'upcoming', title: 'No rush, just a note', body: 'Your OHIP card expires in 18 days. Renewing online takes about 5 minutes.', time: 'Yesterday' },
  { cat: 'Finance', st: 'attention', title: 'Before the deadline', body: 'You have a little RRSP room left. Even a small top-up could trim your tax bill.', time: 'Mon' },
];
function AlertsScreen() {
  return (
    <div style={{ position: 'absolute', inset: 0, overflowY: 'auto', padding: '64px 20px 130px', scrollbarWidth: 'none' }}>
      <div style={{ fontSize: 12.5, fontWeight: 600, color: GREEN }}>The way alerts should feel</div>
      <h1 style={{ margin: '3px 0 4px', fontSize: 27, fontWeight: 700, color: TEXT, letterSpacing: '-0.03em' }}>Calm notifications</h1>
      <p style={{ margin: '0 0 22px', fontSize: 13.5, color: MUTED, lineHeight: 1.5, maxWidth: 300 }}>Human, never robotic. We tell you what matters — and never make you panic.</p>
      {NOTES.map((n, i) => {
        const sem = window.SEM[n.st];
        return (
          <div key={i} style={{ ...surface('solid', { status: n.st, active: true, borderRadius: 22, padding: 16, marginBottom: 13 }) }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
              <div style={{ width: 30, height: 30, borderRadius: 9, background: '#102a26', border: '1px solid rgba(91,198,160,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name="leaf" size={16} color={GREEN_HI} />
              </div>
              <span style={{ fontSize: 12.5, fontWeight: 700, color: TEXT }}>MapleAlerts</span>
              <span style={{ fontSize: 11, color: FAINT }}>· {n.title}</span>
              <span style={{ marginLeft: 'auto', display: 'inline-flex', alignItems: 'center', gap: 5, fontSize: 10.5, fontWeight: 600, color: sem.color, padding: '3px 8px', borderRadius: 8, background: sem.soft }}>
                <span style={{ width: 5, height: 5, borderRadius: 5, background: sem.color }} />{sem.label}
              </span>
            </div>
            <p style={{ margin: 0, fontSize: 14.5, lineHeight: 1.5, color: 'rgba(224,232,240,0.92)', textWrap: 'pretty' }}>{n.body}</p>
            <div style={{ fontSize: 11, color: FAINT, marginTop: 10 }}>{n.time} · {n.cat}</div>
          </div>
        );
      })}
    </div>
  );
}

// ── Timeline ──────────────────────────────────────────────────────────────
function TimelineScreen({ t }) {
  const sorted = [...REMS].sort((a, b) => a.daysLeft - b.daysLeft);
  return (
    <div style={{ position: 'absolute', inset: 0, overflowY: 'auto', padding: '64px 20px 130px', scrollbarWidth: 'none' }}>
      <div style={{ fontSize: 12.5, fontWeight: 600, color: GREEN }}>Your life, on a line</div>
      <h1 style={{ margin: '3px 0 22px', fontSize: 27, fontWeight: 700, color: TEXT, letterSpacing: '-0.03em' }}>Timeline</h1>
      <div style={{ position: 'relative', paddingLeft: 30 }}>
        <div style={{ position: 'absolute', left: 9, top: 6, bottom: 10, width: 2, background: 'linear-gradient(180deg,#5BC6A0,rgba(138,153,172,0.22))', borderRadius: 2 }} />
        {sorted.map(it => {
          const sem = window.SEM[it.status];
          const cat = CATS[it.category];
          const cool = !t.mapleAccent && (it.status === 'urgent' || it.status === 'attention');
          const uc = cool ? '#8FA8C0' : sem.color;
          const passive = it.status === 'planning';
          return (
            <div key={it.id} style={{ position: 'relative', marginBottom: 14 }}>
              <div style={{ position: 'absolute', left: -29, top: 16, width: 14, height: 14, borderRadius: '50%', background: uc, boxShadow: `0 0 0 4px rgba(7,13,21,0.95)${passive ? '' : `, 0 0 10px ${sem.glow}`}` }} />
              <div style={{ ...surface(t.cardStyle, { status: it.status, active: !passive, passive, borderRadius: 18, padding: '13px 15px' }), display: 'flex', alignItems: 'center', gap: 12 }}>
                <Icon name={cat.icon} size={18} color={passive ? C.slate : cat.tint} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14.5, fontWeight: 600, color: passive ? 'rgba(214,224,234,0.8)' : TEXT, letterSpacing: '-0.01em' }}>{it.title}</div>
                  <div style={{ fontSize: 11.5, color: uc, fontWeight: 600, marginTop: 2 }}>{it.when}</div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ── Profile / premium ─────────────────────────────────────────────────────
function ProfileScreen() {
  const perks = ['AI reminders & predictions', 'Document & letter scanning', 'CRA + ServiceCanada sync', 'Family sharing', 'Custom categories'];
  return (
    <div style={{ position: 'absolute', inset: 0, overflowY: 'auto', padding: '64px 20px 130px', scrollbarWidth: 'none' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 24 }}>
        <div style={{ width: 58, height: 58, borderRadius: '50%', background: '#143029', border: '1px solid rgba(91,198,160,0.35)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22, fontWeight: 700, color: GREEN_HI }}>M</div>
        <div>
          <div style={{ fontSize: 20, fontWeight: 700, color: TEXT, letterSpacing: '-0.02em' }}>Maya Chen</div>
          <div style={{ fontSize: 12.5, color: MUTED }}>Toronto, ON · Free plan</div>
        </div>
      </div>
      <div style={{ borderRadius: 26, padding: 22, position: 'relative', overflow: 'hidden', background: 'linear-gradient(155deg,#123a34,#0c2230)', border: '1px solid rgba(91,198,160,0.22)', boxShadow: '0 18px 44px rgba(0,0,0,0.4)' }}>
        <div style={{ position: 'absolute', top: -40, right: -30, width: 150, height: 150, borderRadius: '50%', background: 'radial-gradient(circle,rgba(91,198,160,0.32),transparent 70%)', filter: 'blur(22px)' }} />
        <div style={{ position: 'relative' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginBottom: 10 }}>
            <Icon name="sparkle" size={16} color={GREEN_HI} />
            <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: GREEN_HI }}>MapleAlerts+</span>
          </div>
          <div style={{ fontSize: 20, fontWeight: 700, color: TEXT, letterSpacing: '-0.02em', lineHeight: 1.2 }}>Let it think a few steps ahead of you.</div>
          <div style={{ marginTop: 16, display: 'flex', flexDirection: 'column', gap: 9 }}>
            {perks.map(p => (
              <div key={p} style={{ display: 'flex', alignItems: 'center', gap: 9, fontSize: 13.5, color: 'rgba(224,232,240,0.9)' }}>
                <Icon name="check" size={15} color={GREEN} sw={2} />{p}
              </div>
            ))}
          </div>
          <button style={{ width: '100%', height: 50, marginTop: 18, borderRadius: 15, border: 'none', cursor: 'pointer', background: GREEN, color: '#06231c', fontSize: 14.5, fontWeight: 700, boxShadow: '0 10px 24px rgba(91,198,160,0.26)' }}>Try free for 14 days</button>
          <div style={{ textAlign: 'center', fontSize: 11, color: 'rgba(224,232,240,0.55)', marginTop: 10 }}>Then $4.99/mo · cancel anytime</div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { AddSheet, AlertsScreen, TimelineScreen, ProfileScreen });
