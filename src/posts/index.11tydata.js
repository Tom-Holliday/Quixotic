// src/posts/index.11tydata.js
module.exports = {
  layout: "post.njk",
  tags: ["post"],
  eleventyComputed: {
    permalink: (data) => `/posts/${data.page.fileSlug}/`,
    byline: (data) => data.byline || "Tom Holliday",
  },
};
