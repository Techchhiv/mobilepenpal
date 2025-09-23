import React from "react";
import { Helmet } from "react-helmet-async";

const SITE = "សម្បត្តិ ផ្សារឡាន";
const BASE = "https://www.sambatpsalan.com";

export default function Seo({
  title,                // dynamic piece (e.g., product name)
  description,
  image,
  canonical,            // path only: e.g. `/product/lexus-nx200t-123`
  noIndex = false,
}) {
  const fullTitle = title ? `${SITE} - ${title}` : SITE;
  const canonicalUrl = canonical?.startsWith("http")
    ? canonical
    : `${BASE}${canonical || "/"}`;

  return (
    <Helmet>
      <title>{fullTitle}</title>

      {description && <meta name="description" content={description} />}
      {noIndex && <meta name="robots" content="noindex,nofollow" />}

      {/* Canonical */}
      <link rel="canonical" href={canonicalUrl} />

      {/* Open Graph */}
      <meta property="og:site_name" content={SITE} />
      <meta property="og:type" content="website" />
      <meta property="og:title" content={fullTitle} />
      {description && <meta property="og:description" content={description} />}
      <meta property="og:url" content={canonicalUrl} />
      {image && <meta property="og:image" content={image} />}

      {/* Twitter */}
      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:title" content={fullTitle} />
      {description && <meta name="twitter:description" content={description} />}
      {image && <meta name="twitter:image" content={image} />}
    </Helmet>
  );
}
