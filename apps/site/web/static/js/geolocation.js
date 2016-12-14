export default function($ = window.jQuery) {
  const $locateBtn = $("[data-geolocation-target]");
  if ("geolocation" in navigator) {
    $locateBtn.click(clickHandler($));
  }
  else {
    $locateBtn.hide();
  }
}

// These functions are exported for testing
export function clickHandler($) {
  return (event) => {
    event.preventDefault();
    const $btn = $(event.target);
    $btn.find('.loading-indicator').removeClass('hidden-xs-up');
    $('.transit-near-me-error').addClass('hidden-xs-up');
    navigator.geolocation.getCurrentPosition(
      locationHandler($, $btn),
      locationError($, $btn)
    );
  };
}

export function locationHandler($, $btn) {
  return (location) => {
    $btn.find('.loading-indicator').addClass('hidden-xs-up');
    const loc = window.location;
    window.Turbolinks.visit(encodeURI(`${loc.protocol}//${loc.host}${loc.pathname}?location[address]=${location.coords.latitude}, ${location.coords.longitude}`));
  };
}

export function locationError($, $btn) {
  return (error) => {
    $btn.find('.loading-indicator').addClass('hidden-xs-up');
    if (error.code == error.TIMEOUT || error.code == error.POSITION_UNAVAILABLE) {
      $('.transit-near-me-error').removeClass('hidden-xs-up');
    }
  };
}
