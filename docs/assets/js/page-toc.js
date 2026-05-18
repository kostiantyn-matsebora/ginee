(function () {
  // Build an "On this page" navigation block from H2 headings inside the
  // main content area. Appended to <aside.page-toc[data-auto-toc]> — any
  // section-nav block already inside the aside (rendered by the layout
  // for multi-page sections like /reference/) is preserved.
  //
  // H2-only by default: H3s clutter the sidebar on long pages.
  var aside = document.querySelector('aside.page-toc[data-auto-toc]');
  if (!aside) return;

  var content = document.querySelector('.main-content');
  if (!content) return;

  var headings = [].slice.call(content.querySelectorAll('h2[id]')).filter(function (h) {
    return !aside.contains(h);
  });

  // Less than 2 H2s = TOC isn't useful. Hide the aside if it also has no
  // section-nav child; otherwise leave the section-nav visible.
  var hasSectionNav = aside.querySelector('.section-nav') !== null;
  if (headings.length < 2) {
    if (!hasSectionNav) aside.style.display = 'none';
    return;
  }

  var rootList = document.createElement('ul');
  headings.forEach(function (h) {
    var li = document.createElement('li');
    var a = document.createElement('a');
    a.href = '#' + h.id;
    a.textContent = h.textContent.trim();
    li.appendChild(a);
    rootList.appendChild(li);
  });

  var heading = document.createElement('h4');
  heading.textContent = 'On this page';

  // Append (don't replace) so the layout-rendered section-nav stays.
  aside.appendChild(heading);
  aside.appendChild(rootList);
})();
