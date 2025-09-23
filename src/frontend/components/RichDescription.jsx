import React from "react";
import { Icon } from "@iconify/react";

/** URL + phone + price detectors */
const URL_REGEX =
  /\b((?:https?:\/\/|www\.)[^\s<>"')]+|\bmaps\.app\.goo\.gl\/[^\s<>"')]+)/gi;

// Practical phone detector (+855..., 0xx..., allows spaces/hyphens)
const PHONE_REGEX = /(?<!\w)(\+?\d[\d\-\s]{7,}\d)(?!\w)/g;

// Price must include a $ before or after
const PRICE_REGEX =
  /(?<!\w)(?:\$\s*\d{1,3}(?:[,\s]\d{3})*(?:\.\d+)?|\d{1,3}(?:[,\s]\d{3})*(?:\.\d+)?\s*\$)(?!\w)/gi;

const isImg = (u) => /\.(png|jpe?g|gif|webp|bmp|svg)(\?.*)?$/i.test(u);
const isYouTube = (u) =>
  /(?:youtube\.com\/watch\?v=|youtu\.be\/)([A-Za-z0-9_-]{6,})/i.test(u);
const getYouTubeId = (u) => {
  const m1 = u.match(/v=([A-Za-z0-9_-]{6,})/i);
  const m2 = u.match(/youtu\.be\/([A-Za-z0-9_-]{6,})/i);
  return (m1?.[1] || m2?.[1]) ?? "";
};
const isGMaps = (u) =>
  /(?:google\.[^/]+\/maps|maps\.app\.goo\.gl|goo\.gl\/maps)/i.test(u);
const toGMapsEmbed = (u) => {
  try {
    const url = new URL(u.startsWith("http") ? u : `https://${u}`);
    return `https://www.google.com/maps?q=${encodeURIComponent(url.href)}&output=embed`;
  } catch {
    return `https://www.google.com/maps?q=${encodeURIComponent(u)}&output=embed`;
  }
};
const normalizeUrl = (u) => (u.startsWith("http") ? u : `https://${u}`);
const cleanTel = (s = "") => s.replace(/[^\d+]/g, "");

/** Convert admin HTML to plain text with newlines retained */
function htmlToPlainWithNewlines(input = "") {
  if (!input) return "";
  const asString = String(input)
    .replace(/<(br|BR)\s*\/?>/g, "\n")
    .replace(/<\/(p|div|li|h[1-6]|ul|ol|section|article)>\s*/gi, "\n");
  if (typeof document === "undefined") return asString.replace(/<[^>]*>/g, "");
  const div = document.createElement("div");
  div.innerHTML = asString;
  div.querySelectorAll("li").forEach((li) => {
    li.innerHTML = `• ${li.textContent}`;
  });
  return (div.textContent || div.innerText || "").replace(/\r\n?/g, "\n");
}

/** --- NEW: small map preview block for inline map links --- */
const MapPreview = ({ url, k }) => (
  <div key={k} className="rounded border mb-3 overflow-hidden">
    <div className="px-2 py-1 small text-muted d-flex align-items-center gap-1 bg-light">
      <Icon icon="mdi:map-marker-outline" />
      <span>Map preview</span>
    </div>
    <div className="ratio ratio-4x3">
      <iframe
        title={`map-inline-${k}`}
        src={toGMapsEmbed(url)}
        loading="lazy"
        referrerPolicy="no-referrer-when-downgrade"
        style={{ border: 0 }}
      />
    </div>
  </div>
);

/** Find first Google Maps URL inside arbitrary text */
const firstGmapsInLine = (line) => {
  for (const m of line.matchAll(URL_REGEX)) {
    const u = normalizeUrl(m[0]);
    if (isGMaps(u)) return u;
  }
  return null;
};

export default function RichDescription({ htmlOrText, className = "" }) {
  // 1) Keep exactly what admin typed (including blank lines)
  const text = React.useMemo(
    () => htmlToPlainWithNewlines(htmlOrText),
    [htmlOrText]
  );

  const lines = React.useMemo(() => text.split(/\n/), [text]);

  /** Render a full-line URL as a rich embed/card */
  const renderOnlyUrl = (line, key) => {
    const rawUrl = line.trim();
    const url = normalizeUrl(rawUrl);

    if (isGMaps(url)) {
      return (
        <div
          key={key}
          className="ratio ratio-16x9 rounded overflow-hidden mb-3 border"
        >
          <iframe
            title={`map-${key}`}
            src={toGMapsEmbed(url)}
            loading="lazy"
            referrerPolicy="no-referrer-when-downgrade"
            style={{ border: 0 }}
          />
        </div>
      );
    }
    if (isYouTube(url)) {
      const vid = getYouTubeId(url);
      return (
        <div
          key={key}
          className="ratio ratio-16x9 rounded overflow-hidden mb-3 border"
        >
          <iframe
            title={`yt-${vid}`}
            src={`https://www.youtube.com/embed/${vid}`}
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
            loading="lazy"
          />
        </div>
      );
    }
    if (isImg(url)) {
      return (
        <div key={key} className="mb-3">
          <img
            src={url}
            alt="linked"
            className="img-fluid rounded shadow-sm"
            style={{ maxHeight: 420, objectFit: "contain" }}
          />
        </div>
      );
    }
    // Nice generic link card
    try {
      const u = new URL(url);
      return (
        <a
          key={key}
          href={url}
          target="_blank"
          rel="noopener noreferrer"
          className="d-flex align-items-center justify-content-between rounded border px-3 py-2 text-decoration-none mb-3"
          style={{ background: "#fafafa" }}
        >
          <div className="me-3">
            <div className="fw-semibold">{u.hostname}</div>
            <div className="text-muted small text-truncate" style={{ maxWidth: 360 }}>
              {u.pathname}
              {u.search}
            </div>
          </div>
          <Icon icon="mdi:open-in-new" width="18" className="text-muted" />
        </a>
      );
    } catch {
      return (
        <p key={key} className="mb-3" style={{ whiteSpace: "pre-wrap" }}>
          <a
            href={url}
            target="_blank"
            rel="noopener noreferrer"
            className="link-primary"
          >
            {rawUrl}
          </a>
        </p>
      );
    }
  };

  /** Render a full-line phone as a bold black call card */
  const renderOnlyPhone = (line, key) => {
    const tel = cleanTel(line);
    return (
      <a
        key={key}
        href={`tel:${tel}`}
        className="d-inline-flex align-items-center gap-2 rounded border px-3 py-2 text-decoration-none mb-3"
        style={{ background: "#f8f9fa" }}
      >
        <Icon icon="mdi:phone-outline" />
        <span className="fw-bold text-dark">{line.trim()}</span>
      </a>
    );
  };

  /** Render a full-line price as prominent, bold red */
  const renderOnlyPrice = (line, key) => (
    <p key={key} className="mb-3">
      <span className="fw-bold" style={{ color: "#dc3545", fontSize: "1.1rem" }}>
        {line.trim()}
      </span>
    </p>
  );

  /** Render a line with inline URL/phone/price parts (+ map preview if inline map link exists) */
  const renderTextLine = (line, key) => {
    if (line.trim() === "") return <div key={key} style={{ height: 8 }} />;

    const parts = [];
    let cursor = 0;

    // Collect matches in order; priority: url < phone < price
    const matches = [];
    for (const m of line.matchAll(URL_REGEX))
      matches.push({ type: "url", start: m.index ?? 0, raw: m[0] });
    for (const m of line.matchAll(PHONE_REGEX))
      matches.push({ type: "phone", start: m.index ?? 0, raw: m[0] });
    for (const m of line.matchAll(PRICE_REGEX))
      matches.push({ type: "price", start: m.index ?? 0, raw: m[0] });
    const pri = { url: 0, phone: 1, price: 2 };
    matches.sort((a, b) => a.start - b.start || pri[a.type] - pri[b.type]);

    for (const m of matches) {
      if (m.start > cursor) parts.push(line.slice(cursor, m.start));

      if (m.type === "url") {
        const url = normalizeUrl(m.raw);
        parts.push(
          <a
            key={`${key}-u-${m.start}`}
            href={url}
            target="_blank"
            rel="noopener noreferrer"
            className="link-primary text-break"
          >
            {m.raw}
          </a>
        );
      } else if (m.type === "phone") {
        const tel = cleanTel(m.raw);
        parts.push(
          <a
            key={`${key}-p-${m.start}`}
            href={`tel:${tel}`}
            className="text-decoration-none fw-bold text-dark d-inline-flex align-items-center gap-1"
            title="Call"
          >
            <Icon icon="mdi:phone-outline" />
            {m.raw}
          </a>
        );
      } else {
        // price
        parts.push(
          <span
            key={`${key}-pr-${m.start}`}
            className="fw-bold"
            style={{ color: "#dc3545" }}
          >
            {m.raw}
          </span>
        );
      }
      cursor = m.start + m.raw.length;
    }

    if (cursor < line.length) parts.push(line.slice(cursor));

    // ---- NEW: if this line contains a Google Maps URL, append a compact preview block ----
    const gmUrl = firstGmapsInLine(line);

    return (
      <React.Fragment key={key}>
        <p className="mb-2" style={{ whiteSpace: "pre-wrap" }}>
          {parts}
        </p>
        {gmUrl && <MapPreview url={gmUrl} k={`gm-${key}`} />}
      </React.Fragment>
    );
  };

  return (
    <div className={className}>
      {lines.map((line, idx) => {
        const onlyUrl = new RegExp(`^\\s*(${URL_REGEX.source})\\s*$`, "i");
        if (onlyUrl.test(line)) return renderOnlyUrl(line, `only-url-${idx}`);

        const onlyPhone = new RegExp(`^\\s*(${PHONE_REGEX.source})\\s*$`, "i");
        if (onlyPhone.test(line)) return renderOnlyPhone(line, `only-phone-${idx}`);

        const onlyPrice = new RegExp(`^\\s*(${PRICE_REGEX.source})\\s*$`, "i");
        if (onlyPrice.test(line)) return renderOnlyPrice(line, `only-price-${idx}`);

        return renderTextLine(line, `line-${idx}`);
      })}
    </div>
  );
}
