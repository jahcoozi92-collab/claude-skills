/*
 * orbit-cinematic.js — Ersatz für model-viewers `auto-rotate`
 *
 * Warum: `auto-rotate` dreht mit konstanter Winkelgeschwindigkeit um eine feste
 * Achse, bei fester Höhe und festem Radius. Silhouette und Perspektive ändern
 * sich dabei kaum — das Modell liest sich als Standbild, das geschoben wird.
 *
 * Stattdessen hier drei Oszillatoren mit teilerfremden Perioden (Drehung, Nicken,
 * Dolly), plus Dwell: die Drehung bremst an den beiden 3/4-Hero-Winkeln ab und
 * zieht über die Seiten hinweg an. Das ist die Bewegung einer getragenen Kamera,
 * nicht die eines Drehtellers.
 *
 * Einbinden in viewer.html, NACH dem <model-viewer>-Tag:
 *   <script src="orbit-cinematic.js"></script>
 * und am <model-viewer> die Attribute `auto-rotate`, `auto-rotate-delay` und
 * `rotation-per-second` ENTFERNEN (sonst laufen zwei Treiber gegeneinander).
 *
 * Erwartet ein <model-viewer id="m">. Greift nicht in Kamera-Fit oder
 * Material-Setup ein — es liest die Kameraposition, die dein fitCamera()
 * gesetzt hat, und rechnet von dort aus weiter.
 */
(() => {
  'use strict';

  const CFG = {
    baseSpeed:     10.0,  // deg/s – mittlere Drehgeschwindigkeit; ~44 s je Umdrehung
                          //         (durch Dwell länger als 360/baseSpeed vermuten lässt)
    dwellAmount:   0.55,  // 0..0.9 – wie stark an den Hero-Winkeln gebremst wird
    dwellTheta:    35,    // deg – wo gebremst wird (der Gegenwinkel +180 automatisch)
    phiAmp:        5.0,   // deg – Nick-Amplitude (Kamera hebt und senkt sich)
    phiPeriod:     31,    // s
    radiusAmp:     0.04,  // 4 % – Dolly rein/raus
    radiusPeriod:  19,    // s   (teilerfremd zu phiPeriod → sichtbar keine Schleife)
    rampMs:        1500,  // Einblenden der Bewegung nach Start/Loslassen
    idleMs:        2500,  // Ruhe nach der letzten Nutzer-Interaktion
    settleMs:      350,   // Warten, bis fitCamera + Interpolation gesetzt haben
    respectReducedMotion: true
  };

  const mv = document.getElementById('m');
  if (!mv) return;

  const reduced = CFG.respectReducedMotion &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reduced) return;   // Modell bleibt stehen, wo fitCamera es hingestellt hat

  // model-viewers eigene Drehung abschalten – zwei Treiber auf derselben
  // Kamera ergeben Ruckeln, nicht doppelte Geschwindigkeit.
  mv.removeAttribute('auto-rotate');

  const DEG = 180 / Math.PI;
  const TAU = Math.PI * 2;
  const clamp = (v, lo, hi) => v < lo ? lo : v > hi ? hi : v;
  const smoothstep = t => t * t * (3 - 2 * t);

  let theta = 0, phiBase = 78, rBase = 10;   // Basis, aus der Kamera gelesen
  let t = 0;                                  // Oszillator-Uhr
  let ramp = 0;                               // 0..1 Bewegungsanteil
  let lastInteraction = -1e9;
  let lastFrame = 0;
  let visible = true;
  let running = false;

  // Basis auf die aktuelle Kameraposition setzen. Wird beim Start und bei jeder
  // Nutzer-Interaktion gerufen – dadurch nimmt die Bewegung dort wieder auf, wo
  // der Nutzer losgelassen hat, statt zur alten Position zurückzuspringen.
  function reseed() {
    const o = mv.getCameraOrbit();   // theta/phi in RAD, radius in m
    theta   = o.theta * DEG;
    phiBase = o.phi * DEG;
    rBase   = o.radius;
    t = 0;                            // Oszillatoren bei 0 starten → kein Sprung
  }

  // Drehgeschwindigkeit über den Winkel: langsam an dwellTheta und dwellTheta+180,
  // schnell auf halbem Weg dazwischen. Mittelwert bleibt baseSpeed.
  function speedAt(deg) {
    const phase = 2 * (deg - CFG.dwellTheta) / DEG;
    return CFG.baseSpeed * (1 - CFG.dwellAmount * Math.cos(phase));
  }

  function frame(now) {
    if (!running) return;
    requestAnimationFrame(frame);

    let dt = (now - lastFrame) / 1000;
    lastFrame = now;
    if (dt > 0.05) dt = 0.05;   // Tab-Wechsel/Ruckler nicht als Riesenschritt verarbeiten
    if (dt <= 0) return;

    if (!visible || document.hidden) return;

    // Während und kurz nach der Interaktion: nichts schreiben, nur nachführen.
    // Harter Stopp beim Anfassen ist richtig — der Nutzer hat die Kontrolle.
    // Weich muss nur das Wiederanlaufen sein.
    if (now - lastInteraction < CFG.idleMs) {
      ramp = 0;
      reseed();
      return;
    }

    ramp = clamp(ramp + dt / (CFG.rampMs / 1000), 0, 1);
    const e = smoothstep(ramp);

    t     += dt * e;
    theta += speedAt(theta) * e * dt;
    if (theta > 360) theta -= 360; else if (theta < 0) theta += 360;

    const phi = clamp(phiBase + CFG.phiAmp   * e * Math.sin(TAU * t / CFG.phiPeriod), 5, 175);
    const r   =       rBase * (1 + CFG.radiusAmp * e * Math.sin(TAU * t / CFG.radiusPeriod));

    mv.cameraOrbit = `${theta.toFixed(2)}deg ${phi.toFixed(2)}deg ${r.toFixed(3)}m`;
  }

  function start() {
    if (running) return;
    reseed();
    running = true;
    lastFrame = performance.now();
    requestAnimationFrame(frame);
  }

  const markInteraction = () => { lastInteraction = performance.now(); };

  // camera-change ist der zuverlässige Weg; die Pointer-Events sind Absicherung,
  // falls sich detail.source in einer model-viewer-Version ändert.
  mv.addEventListener('camera-change', ev => {
    if (ev.detail && ev.detail.source === 'user-interaction') markInteraction();
  });
  ['pointerdown', 'wheel', 'touchstart'].forEach(
    ev => mv.addEventListener(ev, markInteraction, { passive: true })
  );

  // Nicht im Hintergrund rechnen: spart Akku in der Companion-App, wo das
  // Dashboard oft offen bleibt.
  if ('IntersectionObserver' in window) {
    new IntersectionObserver(entries => {
      visible = entries[0].isIntersecting;
      lastFrame = performance.now();
    }, { threshold: 0.01 }).observe(mv);
  }
  document.addEventListener('visibilitychange', () => { lastFrame = performance.now(); });

  // load kann schon durch sein, wenn dieses Script spät geparst wird.
  if (mv.loaded) setTimeout(start, CFG.settleMs);
  else mv.addEventListener('load', () => setTimeout(start, CFG.settleMs), { once: true });
})();
