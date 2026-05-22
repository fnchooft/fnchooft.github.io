/**
 * blog.js — shared utilities for fnchooft.dev
 */

export async function loadPosts(root = '') {
  const base = root ? root.replace(/\/?$/, '/') : '';
  const res = await fetch(`${base}posts.json`);
  if (!res.ok) throw new Error('Could not load posts.json');
  return res.json();
}

export function formatDate(iso) {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('en-US', {
    year: 'numeric', month: 'long', day: 'numeric'
  });
}

/**
 * Build a post card <li>.
 * Links go to post.html?p=YYYY/MM/DD (the universal renderer).
 * @param {string} root - relative path to site root ('' from root, '../..' from deep pages)
 */
export function makeCard(post, root = '', size = 'normal') {
  const base = root ? root.replace(/\/?$/, '/') : '';
  const tag  = size === 'large' ? 'h2' : 'h3';
  const href = `${base}post.html?p=${post.path}`;
  const li   = document.createElement('li');
  li.className = 'post-card';
  li.dataset.tag = post.tag;
  li.innerHTML = `
    <div>
      <p class="post-tag">${post.tag}</p>
      <${tag}><a href="${href}">${post.title}</a></${tag}>
      <p class="post-excerpt">${post.excerpt}</p>
    </div>
    <div class="post-meta">${formatDate(post.date)}<br>${post.readingTime} min read</div>
  `;
  return li;
}

export function animateCards(cards) {
  const io = new IntersectionObserver(entries => {
    entries.forEach((e, i) => {
      if (e.isIntersecting) {
        setTimeout(() => e.target.classList.add('visible'), i * 70);
        io.unobserve(e.target);
      }
    });
  }, { threshold: 0.05 });
  cards.forEach(c => io.observe(c));
}
