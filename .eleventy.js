// .eleventy.js

// Optional deps (guarded so the build still runs if they're missing)
let Image;
try {
  Image = require("@11ty/eleventy-img");
} catch (e) {
  console.warn("[warn] @11ty/eleventy-img not installed — image shortcode disabled.");
}

let markdownIt, markdownItAnchor;
try {
  markdownIt = require("markdown-it");
  markdownItAnchor = require("markdown-it-anchor");
} catch (e) {
  console.warn("[warn] markdown-it / markdown-it-anchor not installed — using default markdown renderer.");
}

let pluginRss;
try {
  pluginRss = require("@11ty/eleventy-plugin-rss");
} catch (e) {
  console.warn("[warn] @11ty/eleventy-plugin-rss not installed — RSS filters unavailable.");
}

module.exports = function (eleventyConfig) {
  // --- Core settings --------------------------------------------------------
  eleventyConfig.setDataDeepMerge(true);

  // --- Filters --------------------------------------------------------------
  // Edit-on-GitHub URL
  eleventyConfig.addFilter("editOnGitHub", (inputPath) => {
    const repo   = "Tom-Holliday/Quixotic";
    const branch = "main";
    const p = (inputPath || "").replace(/^\.?\//, ""); // './src/...' -> 'src/...'
    return `https://github.com/${repo}/edit/${branch}/${p}`;
  });

  // Related posts (by overlapping tags)
  eleventyConfig.addFilter("relatedPosts", (collection = [], page, max = 3) => {
    if (!page || !page.data) return [];
    const IGNORE = new Set(["post", "posts", "all"]);
    const currentTags = new Set((page.data.tags || []).filter(t => !IGNORE.has(t)));
    if (!currentTags.size) return [];

    return collection
      .filter(p => p && p.url && p.url !== page.url)
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

  // Dates
  eleventyConfig.addFilter("dateIso", (value) => {
    if (!value) return "";
    const d = new Date(value);
    return isNaN(d) ? "" : d.toISOString();
  });

  eleventyConfig.addFilter("dateDisplay", (value) => {
    if (!value) return "";
    const d = new Date(value);
    if (isNaN(d)) return "";
    return new Intl.DateTimeFormat("en-GB", { day: "2-digit", month: "short", year: "numeric" }).format(d);
  });

  // Helper
  eleventyConfig.addFilter("indexOf", (arr, item) => {
    if (!Array.isArray(arr) || !item) return -1;
    return arr.findIndex((x) => x.url === item.url);
  });

  // --- Plugins --------------------------------------------------------------
  if (pluginRss) {
    eleventyConfig.addPlugin(pluginRss);
  }

  // --- Markdown with anchors -----------------------------------------------
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
        slugify: (s) => s.trim().toLowerCase().replace(/[^\w]+/g, "-"),
      });
    }
    eleventyConfig.setLibrary("md", md);
  }

  // --- Collections ----------------------------------------------------------
  const postsGlob = "./src/posts/**/*.md";

  eleventyConfig.addCollection("postsSorted", (collection) =>
    collection.getFilteredByGlob(postsGlob).sort((a, b) => b.date - a.date)
  );

  eleventyConfig.addCollection("postsPublishedSorted", (collection) =>
    collection.getFilteredByGlob(postsGlob)
      .filter((p) => !p.data.draft)
      .sort((a, b) => b.date - a.date)
  );

  eleventyConfig.addCollection("postsDraftsSorted", (collection) =>
    collection.getFilteredByGlob(postsGlob)
      .filter((p) => p.data.draft)
      .sort((a, b) => b.date - a.date)
  );

  // --- Shortcodes -----------------------------------------------------------
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

  // --- Passthrough / Watch --------------------------------------------------
  eleventyConfig.addPassthroughCopy({ "src/assets": "assets" });
  eleventyConfig.addPassthroughCopy({ "src/admin": "admin" });
  eleventyConfig.addWatchTarget("src/assets/css/");
  eleventyConfig.addWatchTarget("src/assets/js/");
eleventyConfig.addPassthroughCopy("_headers");

  // --- Return directories / engines ----------------------------------------
  return {
    dir: {
      input: "src",
      includes: "_includes",
      layouts: "_includes/layouts",
      data: "_data",
      output: "_site",
    },
    markdownTemplateEngine: "njk",
    htmlTemplateEngine: "njk",
    dataTemplateEngine: "njk",
    templateFormats: ["md", "njk", "html"],
    passthroughFileCopy: true,
  };
};
