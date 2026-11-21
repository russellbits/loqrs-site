#!/usr/bin/env bash
# Prints one line of layout measurements for the LOQRS home page.
# Usage: scripts/check-layout.sh <width> <height>
# Prerequisites: `astro dev` running on http://localhost:1217/ and
# agent-browser installed. Override URL= if the port differs.
set -euo pipefail

WIDTH="${1:?usage: check-layout.sh <width> <height>}"
HEIGHT="${2:?usage: check-layout.sh <width> <height>}"
URL="${URL:-http://localhost:1217/}"
SESSION="${AGENT_BROWSER_SESSION:-loqrs-responsive}"

agent-browser --session "$SESSION" set viewport "$WIDTH" "$HEIGHT" >/dev/null 2>&1
agent-browser --session "$SESSION" open "$URL" >/dev/null 2>&1
sleep 1

agent-browser --session "$SESSION" eval "(() => {
  const r = v => Math.round(v);
  const vw = innerWidth;
  const steps = document.querySelectorAll('.guide-step');
  const tops = new Set([...steps].map(s => r(s.getBoundingClientRect().top)));
  const ig = document.querySelector('.input-group');
  const igr = ig && ig.getBoundingClientRect();
  const igcs = ig && getComputedStyle(ig);
  const img = document.querySelector('.lockers-row img');
  const g = document.querySelector('.graffiti');
  const gr = g && g.getBoundingClientRect();
  const banner = document.querySelector('section.banner');
  const bcta = document.querySelector('.beta-cta');
  const h2 = document.querySelector('.beta-cta h2');
  const h2r = h2 && h2.getBoundingClientRect();
  return [
    'vw=' + vw,
    'scrollW=' + document.documentElement.scrollWidth,
    'rows=' + tops.size,
    'stepW=' + [...steps].map(s => r(s.getBoundingClientRect().width)).join(','),
    'stepLeft=' + (steps.length ? r(steps[0].getBoundingClientRect().left) : 'n/a'),
    'stepRight=' + (steps.length ? r(steps[steps.length-1].getBoundingClientRect().right) : 'n/a'),
    'igDir=' + (igcs ? igcs.flexDirection : 'n/a'),
    'igW=' + (igr ? r(igr.width) : 'n/a'),
    'locker=' + (img ? img.currentSrc.replace(location.origin, '') : 'n/a'),
    'lockerH=' + (img ? r(img.getBoundingClientRect().height) : 'n/a'),
    'bannerDisplay=' + (banner ? getComputedStyle(banner).display : 'n/a'),
    'ctaDisplay=' + (bcta ? getComputedStyle(bcta).display : 'n/a'),
    'h2W=' + (h2r ? r(h2r.width) : 'n/a'),
    'graffitiLeft=' + (gr ? r(gr.left) : 'n/a'),
    'graffitiRight=' + (gr ? r(gr.right) : 'n/a')
  ].join(' ');
})()" 2>/dev/null | tail -1 | tr -d '"'
