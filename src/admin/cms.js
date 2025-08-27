/* Register preview CSS (optional) */
if (window.CMS && CMS.registerPreviewStyle) {
  CMS.registerPreviewStyle('/assets/css/main.css');
}

/* Convert between repo path and public URL */
function toPublic(path) {
  return (path || '').replace(/^src\//, '/');
}
function toRepoPath(path) {
  return (path || '').replace(/^\/assets\/img\//, 'src/assets/img/');
}

/* 1) Responsive Eleventy Image ({% img %} shortcode) */
CMS.registerEditorComponent({
  id: "eleventy-img",
  label: "Responsive Image",
  fields: [
    { name: "image", label: "Image", widget: "image", media_library: { allow_multiple: false } },
    { name: "alt", label: "Alt text", widget: "string", hint: "Describe the image for accessibility" },
    { name: "widths", label: "Widths (comma-separated)", widget: "string", required: false, hint: "e.g. 400,800,1200" },
    { name: "sizes", label: "Sizes", widget: "string", required: false, default: "(min-width: 768px) 800px, 100vw" }
  ],
  pattern: /{%\s*img\s+"([^"]+)"\s*,\s*"([^"]*)"(?:\s*,\s*\[([^\]]*)\])?(?:\s*,\s*"([^"]*)")?\s*%}/,
  fromBlock: (m) => ({
    image: toPublic(m[1] || ""),
    alt: m[2] || "",
    widths: (m[3] || "").replace(/\s+/g, ""),
    sizes: m[4] || ""
  }),
  toBlock: ({ image, alt, widths, sizes }) => {
    if (!image) return "";
    const repoPath = toRepoPath(image);
    const w = widths ? `, [${widths}]` : "";
    const s = sizes ? `, "${sizes}"` : "";
    return `{% img "${repoPath}", "${alt || ""}"${w}${s} %}`;
  },
  toPreview: ({ image, alt }) =>
    `<img src="${toPublic(image)}" alt="${alt || ""}" style="max-width:100%;height:auto;border:1px solid #ddd;border-radius:8px;padding:2px;">`
});

/* 2) Plain Markdown image */
CMS.registerEditorComponent({
  id: "md-image",
  label: "Markdown Image",
  fields: [
    { name: "image", label: "Image", widget: "image", media_library: { allow_multiple: false } },
    { name: "alt", label: "Alt text", widget: "string" },
    { name: "title", label: "Title (optional)", widget: "string", required: false }
  ],
  pattern: /!\[([^\]]*)\]\(([^\s)]+)(?:\s+"([^"]+)")?\)/,
  fromBlock: (m) => ({ alt: m[1] || "", image: m[2] || "", title: m[3] || "" }),
  toBlock: ({ image, alt, title }) => {
    if (!image) return "";
    const url = toPublic(image);
    return title && title.trim().length
      ? `![${alt || ""}](${url} "${title}")`
      : `![${alt || ""}](${url})`;
  },
  toPreview: ({ image, alt, title }) => {
    const url = toPublic(image);
    const t = title ? ` title="${title}"` : "";
    return `<img src="${url}" alt="${alt || ""}"${t} style="max-width:100%;height:auto;border:1px solid #ddd;border-radius:8px;padding:2px;">`;
  }
});