// src/posts/index.11tydata.js
module.exports = (data) => {
  const collections = data.collections || {};
  const items = collections.postsPublishedSorted || [];
  const hasItems = items.length > 0;

  // Always keep pagination.data as a STRING key.
  // We point it to "paginationItems" which we define below.
  return {
    eleventyExcludeFromCollections: true,

    // When empty, give Eleventy a one-item array so it still makes one page.
    paginationItems: hasItems ? items : [ { __empty: true } ],

    pagination: {
      data: "paginationItems", // <-- string, not an array
      size: 6,
      alias: "posts"
    },

    // Stable permalink: /posts/ (then /posts/page/2, /3, … if there are posts)
    permalink: (ctx) => {
      const c = ctx.collections || {};
      const list = c.postsPublishedSorted || [];
      const has = list.length > 0;
      const pageNum = (ctx.pagination && ctx.pagination.pageNumber) || 0;

      if (!has) return "/posts/index.html";
      return pageNum === 0 ? "/posts/index.html" : `/posts/page/${pageNum + 1}.html`;
    }
  };
};
