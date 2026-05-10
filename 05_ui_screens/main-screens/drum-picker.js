/**
 * DrumPicker — universal iOS-style scroll wheel picker
 * 
 * API:
 *   DrumPicker.openTime(title, {h, m}, callback)
 *   DrumPicker.openNumber(title, {value, min, max, step, suffix}, callback)
 *
 * Number picker includes a "Ввести вручную" toggle for manual keyboard input.
 */
const DrumPicker = (() => {
  let overlay, sheet, titleEl, bodyEl, labelRow, doneBtn, kbToggle;
  let _callback = null;
  let _mode = null;      // 'time' | 'number'
  let _kbMode = false;   // keyboard input active?
  let _items = {};       // {col1: [...], col2: [...]}
  let _scrollEls = {};
  let _numOpts = {};     // {min, max, step, suffix}

  // ══════ DOM Bootstrap ══════
  function ensureDOM() {
    if (overlay) return;
    overlay = document.createElement('div');
    overlay.className = 'picker-overlay';
    overlay.onclick = close;

    sheet = document.createElement('div');
    sheet.className = 'picker-sheet';
    sheet.innerHTML = `
      <div class="picker-handle"></div>
      <div class="picker-header">
        <span class="picker-title"></span>
        <button class="picker-done-btn">Готово</button>
      </div>
      <div class="drum-label-row"></div>
      <div class="picker-body"></div>
      <div class="picker-kb-toggle"></div>`;

    titleEl = sheet.querySelector('.picker-title');
    doneBtn = sheet.querySelector('.picker-done-btn');
    labelRow = sheet.querySelector('.drum-label-row');
    bodyEl = sheet.querySelector('.picker-body');
    kbToggle = sheet.querySelector('.picker-kb-toggle');
    doneBtn.onclick = confirm;

    document.body.appendChild(overlay);
    document.body.appendChild(sheet);
  }

  // ══════ Drum Helpers ══════
  const ITEM_H = 44;
  const PAD = 2;

  function buildDrum(el, items) {
    let html = '';
    for (let i = 0; i < PAD; i++) html += '<div class="drum-item drum-pad"></div>';
    items.forEach((v, idx) => {
      html += `<div class="drum-item" data-idx="${idx}">${v}</div>`;
    });
    for (let i = 0; i < PAD; i++) html += '<div class="drum-item drum-pad"></div>';
    el.innerHTML = html;
  }

  function snapIndex(el) { return Math.round(el.scrollTop / ITEM_H); }

  function updateStyle(el) {
    const si = el.scrollTop / ITEM_H;
    el.querySelectorAll('.drum-item:not(.drum-pad)').forEach((item, i) => {
      const d = Math.abs(i - si);
      if (d < 0.6)       item.style.cssText = 'font-size:26px;font-weight:800;color:var(--color-text-primary,#1F2937);opacity:1';
      else if (d < 1.5)  item.style.cssText = 'font-size:20px;font-weight:700;color:#6B7280;opacity:0.8';
      else if (d < 2.5)  item.style.cssText = 'font-size:15px;font-weight:600;color:#9CA3AF;opacity:0.5';
      else               item.style.cssText = 'font-size:12px;font-weight:600;color:#9CA3AF;opacity:0.2';
    });
  }

  function bindDrum(el, maxIdx) {
    let timer;
    el.addEventListener('scroll', () => {
      updateStyle(el);
      clearTimeout(timer);
      timer = setTimeout(() => {
        const idx = Math.max(0, Math.min(snapIndex(el), maxIdx));
        el.scrollTo({ top: idx * ITEM_H, behavior: 'smooth' });
      }, 120);
    }, { passive: true });
  }

  function scrollTo(el, idx) {
    el.scrollTop = idx * ITEM_H;
    setTimeout(() => updateStyle(el), 20);
  }

  function drumCol() {
    const wrap = document.createElement('div');
    wrap.className = 'drum-col';
    wrap.innerHTML = `
      <div class="drum-wrap">
        <div class="drum-scroll"></div>
        <div class="drum-highlight"></div>
        <div class="drum-fade drum-fade-top"></div>
        <div class="drum-fade drum-fade-bot"></div>
      </div>`;
    return wrap;
  }

  // ══════ Keyboard Mode ══════
  function toggleKeyboard() {
    _kbMode = !_kbMode;
    if (_kbMode) {
      // Get current drum value
      const VALS = _items.col1;
      const vi = Math.max(0, Math.min(snapIndex(_scrollEls.col1), VALS.length - 1));
      const curVal = VALS[vi];

      bodyEl.innerHTML = `
        <div class="picker-kb-input-wrap">
          <input type="number" class="picker-kb-input" inputmode="decimal"
                 value="${curVal}" min="${_numOpts.min}" max="${_numOpts.max}" step="${_numOpts.step}"
                 autofocus>
          ${_numOpts.suffix ? `<span class="picker-kb-suffix">${_numOpts.suffix}</span>` : ''}
        </div>`;
      const inp = bodyEl.querySelector('.picker-kb-input');
      setTimeout(() => { inp.focus(); inp.select(); }, 50);
      kbToggle.innerHTML = '<span class="picker-kb-btn">🎡 Колесо</span>';
    } else {
      // Read typed value and rebuild drum
      const inp = bodyEl.querySelector('.picker-kb-input');
      const typed = inp ? parseFloat(inp.value) : _numOpts.value;
      rebuildDrum(typed);
      kbToggle.innerHTML = '<span class="picker-kb-btn">⌨ Ввести вручную</span>';
    }
  }

  function rebuildDrum(value) {
    const { min, max, step, suffix } = _numOpts;
    const VALS = [];
    for (let v = min; v <= max; v += step) {
      VALS.push(step < 1 ? v.toFixed(1) : String(v));
    }
    _items = { col1: VALS };
    bodyEl.innerHTML = '';

    const c1 = drumCol();
    bodyEl.appendChild(c1);
    if (suffix) {
      const suf = document.createElement('div');
      suf.className = 'drum-suffix';
      suf.textContent = suffix;
      bodyEl.appendChild(suf);
    }

    const s1 = c1.querySelector('.drum-scroll');
    _scrollEls = { col1: s1 };
    buildDrum(s1, VALS);
    bindDrum(s1, VALS.length - 1);

    let bestIdx = 0, bestDiff = Infinity;
    VALS.forEach((v, i) => {
      const diff = Math.abs(parseFloat(v) - value);
      if (diff < bestDiff) { bestDiff = diff; bestIdx = i; }
    });
    scrollTo(s1, bestIdx);
  }

  // ══════ Open / Close ══════
  function show() {
    requestAnimationFrame(() => {
      overlay.classList.add('visible');
      sheet.classList.add('visible');
    });
  }

  function close() {
    overlay.classList.remove('visible');
    sheet.classList.remove('visible');
    _callback = null;
    _kbMode = false;
  }

  function confirm() {
    if (!_callback) return;
    if (_mode === 'time') {
      const HOURS = _items.col1;
      const MINS = _items.col2;
      const hi = Math.max(0, Math.min(snapIndex(_scrollEls.col1), HOURS.length - 1));
      const mi = Math.max(0, Math.min(snapIndex(_scrollEls.col2), MINS.length - 1));
      _callback({ h: parseInt(HOURS[hi]), m: parseInt(MINS[mi]) });
    } else if (_kbMode) {
      // Read from text input
      const inp = bodyEl.querySelector('.picker-kb-input');
      let v = parseFloat(inp ? inp.value : 0);
      v = Math.max(_numOpts.min, Math.min(_numOpts.max, v));
      _callback(v);
    } else {
      const VALS = _items.col1;
      const vi = Math.max(0, Math.min(snapIndex(_scrollEls.col1), VALS.length - 1));
      _callback(parseFloat(VALS[vi]));
    }
    close();
  }

  // ══════ Public API ══════
  function openTime(title, { h, m }, cb) {
    ensureDOM();
    _mode = 'time';
    _kbMode = false;
    _callback = cb;
    titleEl.textContent = title;
    kbToggle.innerHTML = ''; // no manual input for time

    const HOURS = Array.from({ length: 24 }, (_, i) => String(i).padStart(2, '0'));
    const MINS = Array.from({ length: 12 }, (_, i) => String(i * 5).padStart(2, '0'));
    _items = { col1: HOURS, col2: MINS };

    labelRow.innerHTML = '<div class="drum-sublabel">Часы</div><div class="drum-sep-space"></div><div class="drum-sublabel">Минуты</div>';
    bodyEl.innerHTML = '';

    const c1 = drumCol();
    const sep = document.createElement('div');
    sep.className = 'drum-sep';
    sep.textContent = ':';
    const c2 = drumCol();

    bodyEl.appendChild(c1);
    bodyEl.appendChild(sep);
    bodyEl.appendChild(c2);

    const s1 = c1.querySelector('.drum-scroll');
    const s2 = c2.querySelector('.drum-scroll');
    _scrollEls = { col1: s1, col2: s2 };

    buildDrum(s1, HOURS);
    buildDrum(s2, MINS);
    bindDrum(s1, HOURS.length - 1);
    bindDrum(s2, MINS.length - 1);
    scrollTo(s1, h);
    scrollTo(s2, Math.round(m / 5) % 12);

    show();
  }

  function openNumber(title, { value, min, max, step = 1, suffix = '' }, cb) {
    ensureDOM();
    _mode = 'number';
    _kbMode = false;
    _callback = cb;
    _numOpts = { value, min, max, step, suffix };
    titleEl.textContent = title;

    labelRow.innerHTML = '';
    kbToggle.innerHTML = '<span class="picker-kb-btn">⌨ Ввести вручную</span>';
    kbToggle.onclick = toggleKeyboard;

    rebuildDrum(value);
    show();
  }

  return { openTime, openNumber, close };
})();
