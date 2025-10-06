console.log(">>> Using Eleventy config from:", __filename);

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { DateTime } = require("luxon");

// Optional deps (don’t crash if missing)
let Image, markdownIt, markdownItAnchor, pluginRss;
try { Image = require("@11ty/eleventy-img"); } catch {}
try {
  markdownIt = require("markdown-it");
  markdownItAnchor = require("markdown-it-anchor");
} catch {}
try { pluginRss = require("@11ty/eleventy-plugin-rss"); } catch {}

// Helpers
function srcFromWebPath(webPath) {
  if (!webPath) return null;
  if (webPath.startsWith("/assets/")) return path.join("./src", webPath);
  if (webPath.startsWith("src/assets/")) return "./" + webPath.replace(/^\.?\//, "");
  return null;
}
const htmlToText = (html = "") =>
  html.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();

module.exports = function (eleventyConfig) {
  eleventyConfig.setDataDeepMerge(true);

  // --- Layout aliases (keep simple, filenames only) ---
  eleventyConfig.addLayoutAlias("base", "base.njk");
  eleventyConfig.addLayoutAlias("post", "post.njk");

  // --- Filters ---
  eleventyConfig.addFilter("editOnGitHub", (inputPath) => {
    const repo = "Tom-Holliday/Quixotic";
    const branch = "main";
    const p = (inputPath || "").replace(/^\.?\//, "");
    return `https://github.com/${repo}/edit/${branch}/${p}`;
  });

  eleventyConfig.addFilter("assetHash", (webPath) => {
    try {
      const srcPath = srcFromWebPath(webPath);
      if (!srcPath || !fs.existsSync(srcPath)) return Date.now().toString();
      const buf = fs.readFileSync(srcPath);
      return crypto.createHash("md5").update(buf).digest("hex").slice(0, 10);
    } catch {
      return Date.now().toString();
    }
  });

  eleventyConfig.addFilter("relatedPosts", (collection = [], page, max = 3) => {
    if (!page?.data) return [];
    const IGNORE = new Set(["post", "posts", "all"]);
    const currentTags = new Set((page.data.tags || []).filter(t => !IGNORE.has(t)));
    if (!currentTags.size) return [];
    return collection
      .filter(p => p.url && p.url !== page.url)
      .map(p => {
        const tags = Array.isArray(p.data?.tags) ? p.data.tags : [];
        const overlap = tags.filter(t => currentTags.has(t)).length;
        const date = new Date(p.date || p.data?.date || 0).getTime() || 0;
        return { p, score: overlap, date };
      })
      .filter(x => x.score > 0)
      .sort((a, b) => (b.score - a.score) || (b.date - a.date))
      .slice(0, max)
      .map(x => x.p);
  });

  eleventyConfig.addFilter("dateIso", (v) =>
    v ? new Date(v).toISOString() : ""
  );

  eleventyConfig.addFilter("dateDisplay", (v) => {
    if (!v) return "";
    const d = new Date(v);
    return isNaN(d)
      ? ""
      : new Intl.DateTimeFormat("en-GB", {
          day: "2-digit",
          month: "short",
          year: "numeric",
        }).format(d);
  });

  eleventyConfig.addFilter("indexOf", (arr, item) =>
    Array.isArray(arr) ? arr.findIndex(x => x.url === item.url) : -1
  );

  eleventyConfig.addFilter("splitLines", (v) =>
    v ? String(v).replace(/\r\n?/g, "\n").split("\n") : []
  );

  eleventyConfig.addFilter("readingTime", (content) => {
    const words = htmlToText(content).split(" ").filter(Boolean).length;
    const mins = Math.max(1, Math.round(words / 200));
    return `${mins} min read`;
  });

  // Universal date filter
  eleventyConfig.addFilter("date", (dateObj, fmt = "dd LLL yyyy") => {
    if (!dateObj) return "";
    const dt = typeof dateObj === "string"
      ? DateTime.fromISO(dateObj)
      : DateTime.fromJSDate(dateObj);
    return dt.isValid ? dt.toFormat(fmt) : "";
  });

  // --- Plugins ---
  if (pluginRss) {
    eleventyConfig.addPlugin(pluginRss);
    // RSS helpers used by feed.xml
    eleventyConfig.addFilter("absoluteUrl", pluginRss.absoluteUrl);
    eleventyConfig.addFilter("dateToRfc822", pluginRss.dateToRfc822);
  }

  // --- Markdown ---
  if (markdownIt) {
    const md = markdownIt({ html: true, linkify: true, typographer: true });
    if (markdownItAnchor) {
      md.use(markdownItAnchor, {
        permalink: markdownItAnchor.permalink.ariaHidden({
          placement: "after",
          class: "anchor-link",
          symbol: "#",
          level: [1, 2, 3, 4],
        }),
        slugify: (s) =>
          s.trim().toLowerCase().replace(/[^\w]+/g, "-"),
      });
    }
    eleventyConfig.setLibrary("md", md);
  }

  // --- Collections ---
  const postsGlob = "./src/posts/**/*.md";
  eleventyConfig.addCollection("postsSorted", (c) =>
    c.getFilteredByGlob(postsGlob).sort((a, b) => b.date - a.date)
  );
  eleventyConfig.addCollection("postsPublishedSorted", (c) =>
    c.getFilteredByGlob(postsGlob).filter(p => !p.data.draft).sort((a, b) => b.date - a.date)
  );
  eleventyConfig.addCollection("postsDraftsSorted", (c) =>
    c.getFilteredByGlob(postsGlob).filter(p => p.data.draft).sort((a, b) => b.date - a.date)
  );

  // --- Shortcodes ---
  if (Image) {
    eleventyConfig.addNunjucksAsyncShortcode(
      "img",
      async (src, alt = "", widths = [400, 800, 1200], sizes = "(min-width: 768px) 800px, 100vw") => {
        const metadata = await Image(src, {
          widths,
          formats: ["webp", "jpeg"],
          urlPath: "/assets/img/",
          outputDir: "./_site/assets/img/",
        });
        const attrs = {
          alt,
          sizes,
          loading: "lazy",
          decoding: "async",
          class: "rounded",
        };
        return Image.generateHTML(metadata, attrs, { whitespaceMode: "inline" });
      }
    );
  }

  // --- Passthrough / Watch ---
  eleventyConfig.addPassthroughCopy({ "src/assets": "assets" });
  eleventyConfig.addPassthroughCopy({ "src/admin": "admin" });
  eleventyConfig.addPassthroughCopy({ "src/img": "img" });
  eleventyConfig.addPassthroughCopy("_headers");
  eleventyConfig.addWatchTarget("src/assets/css/");
  eleventyConfig.addWatchTarget("src/assets/js/");

  // --- Directories ---
  return {
    dir: {
      input: "src",
      includes: "_includes",        // where base.njk and post.njk live
      data: "_data",
      layouts: "_includes/layouts", // where layouts/ filenames resolve from
      output: "_site",
    },
    markdownTemplateEngine: "njk",
    htmlTemplateEngine: "njk",
    dataTemplateEngine: "njk",
    templateFormats: ["md", "njk", "html"],
    passthroughFileCopy: true,
  };
};
