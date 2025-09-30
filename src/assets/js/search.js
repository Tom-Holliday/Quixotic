(async function () {
  const input = document.getElementById('search');
  const resultsList = document.getElementById('results');
  if (!input || !resultsList) return;

  const res = await fetch('/search.json', { cache: 'no-store' });
  const posts = await res.json();

  const index = new FlexSearch.Document({
    document: { id: 'url', index: ['title', 'excerpt'], store: ['title', 'url', 'excerpt'] },
    tokenize: 'forward',
    encode: 'icase' // case-insensitive search helps a lot
  });
  posts.forEach(p => index.add(p));

  const render = (items) => {
    resultsList.innerHTML = '';
    if (!items.length) { resultsList.style.display = 'none'; return; }
    items.forEach(({ doc }) => {
      const li = document.createElement('li');
      li.innerHTML = `
        <a href="${doc.url}">
          <strong>${doc.title}</strong><br>
          <small>${doc.excerpt || ''}</small>
        </a>`;
      resultsList.appendChild(li);
    });
    resultsList.style.display = 'block'; // <-- make it visible
  };

  input.addEventListener('input', () => {
    const q = input.value.trim();
    if (!q) { resultsList.innerHTML = ''; resultsList.style.display = 'none'; return; }

    const raw = index.search(q, { enrich: true });
    // flatten + de-dup
    const seen = new Set();
    const flat = [];
    raw.forEach(r => r.result.forEach(({ doc }) => {
      if (!seen.has(doc.url)) { seen.add(doc.url); flat.push({ doc }); }
    }));
    render(flat.slice(0, 8));
  });

  // Click outside to close (optional)
  document.addEventListener('click', (e) => {
    if (!resultsList.contains(e.target) && e.target !== input) {
      resultsList.style.display = 'none';
    }
  });
})();
