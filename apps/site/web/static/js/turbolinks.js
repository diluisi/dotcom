export default function($) {
  $ = $ || window.jQuery;

  var savedPosition = null;
  var savedAnchor = null;

  Turbolinks.start();
  $(document).on('turbolinks:before-visit', (ev) => {
    const url = ev.originalEvent.data.url;
    const anchorIndex = url.indexOf('#');
    const currentPath = `${window.location.protocol}//${window.location.host}${window.location.pathname}`;
    if (anchorIndex !== -1) {
      const newUrl = url.slice(0, anchorIndex);
      const rest = url.slice(anchorIndex, url.length);
      if (!samePath(`${currentPath}${window.location.search}`, newUrl)) {
        ev.preventDefault();
        ev.stopPropagation();
        savedAnchor = rest;
        window.setTimeout(() => Turbolinks.visit(newUrl), 0);
      }
      return;
    }

    if (samePath(url, currentPath)) {
      savedPosition = [window.scrollX, window.scrollY];
    }

  });
  $(document).on('turbolinks:render', (ev) => {
    if (savedPosition) {
      window.scrollTo.apply(window, savedPosition);
      savedPosition = null;
    }
    if (savedAnchor) {
      // if we saved the anchor and it's above the screen, scroll to it
      const $el = $(savedAnchor);
      const $window = $(window);
      savedAnchor = null;
      if ($el.length > 0) {
        const elementY = $el.offset().top;
        const windowY = $window.scrollTop();
        if (windowY > elementY) {
          $window.scrollTop(elementY - 20);
        }
        $el.children().first().focus();
      }
    }
  });
};

export function samePath(first, second) {
  return (first.slice(0, second.length) === second && (
    first.length == second.length || first[second.length] === "?"));
};
