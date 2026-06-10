// settings-loader.js — include on every page via <script src="js/settings-loader.js" defer>
// Fetches system + banner settings and injects banners without touching existing markup.
(async function () {
  try {
    const [sysRes, banRes] = await Promise.all([
      fetch('/api/settings?category=system'),
      fetch('/api/settings?category=banner')
    ]);

    const sysData = sysRes.ok ? (await sysRes.json()).data || [] : [];
    const banData = banRes.ok ? (await banRes.json()).data || [] : [];

    const sys = {};
    sysData.forEach((s) => { sys[s.key] = s.value; });

    const ban = {};
    banData.forEach((s) => { ban[s.key] = s.value; });

    // ── Maintenance mode ─────────────────────────────────────────────────
    if (sys['system.maintenanceMode'] === true) {
      const msg = sys['system.maintenanceMessage'] ||
        'We are currently performing maintenance. Back shortly!';
      const el = document.createElement('div');
      el.id = 'oz-maintenance-banner';
      el.style.cssText =
        'position:fixed;top:0;left:0;right:0;z-index:9999;' +
        'background:#dc2626;color:#fff;text-align:center;' +
        'padding:10px 16px;font-size:14px;font-family:Inter,sans-serif;' +
        'font-weight:600;line-height:1.4;';
      el.textContent = '🔧 ' + msg;
      document.body.prepend(el);
    }

    // ── Bookings disabled ────────────────────────────────────────────────
    if (sys['system.bookingsEnabled'] === false) {
      document.querySelectorAll('a[href*="book.html"]').forEach((link) => {
        link.style.pointerEvents = 'none';
        link.style.opacity = '0.45';
        link.title = 'Bookings are temporarily unavailable.';
      });
    }

    // ── Promo banner ─────────────────────────────────────────────────────
    if (ban['banner.promo.enabled'] === true) {
      const text = ban['banner.promo.text'] || '';
      const color = ban['banner.promo.color'] || '#f59e0b';
      if (text) {
        const el = document.createElement('div');
        el.id = 'oz-promo-banner';
        el.style.cssText =
          `background:${color};color:#000;text-align:center;` +
          'padding:10px 16px;font-size:14px;font-family:Inter,sans-serif;' +
          'font-weight:600;line-height:1.4;';
        el.textContent = '🎉 ' + text;
        document.body.prepend(el);
      }
    }
  } catch {
    // Fail silently — never break the page if the API is unreachable.
  }
})();
