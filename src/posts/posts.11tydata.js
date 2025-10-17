// src/posts/posts.11tydata.js
module.exports = {
  layout: "post.njk",
  tags: ["post"],
  eleventyComputed: {
    // Default author/byline; per-post `author` or `byline` will override.
    author: (data) => data.author || data.metadata?.author || "Tom Holliday",
    byline: (data) =>
      data.byline || `By ${data.author || data.metadata?.author || "Tom Holliday"}`,

    // Only set a permalink if the post didn’t define one.
    permalink: (data) =>
      data.permalink ?? `/posts/${data.page.fileSlug}/`,
  },
};
