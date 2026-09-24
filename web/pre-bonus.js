// pre-bonus.js — bonus web build defaults. Runs before the emscripten module
// is initialized:
//  - the scene dropdown lists the bonus scenes as well as the mandatory ones
//  - default scene is a bonus scene (all objects) unless ?scene= is given
(function () {
  var query = new URLSearchParams(window.location.search);
  window.__minirtSceneDirs = ['/scenes/mandatory', '/scenes/bonus'];
  if (!query.get('scene') && typeof Module !== 'undefined') {
    Module.arguments = ['/scenes/bonus/all_objects.rt'];
  }
})();
