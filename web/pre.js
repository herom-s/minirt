// pre.js — runs before the emscripten module is initialized.
//  - forwards stdout/stderr to the browser console
//  - logs the program exit code (main returning EXIT_FAILURE sets code 1)
//  - sets window.__minirtMainStarted right before main() runs, so the shell
//    can tell when the (synchronous) render is done: rAF only ticks again
//    once SampaLX's emscripten main loop takes over.
console.log('[miniRT] pre.js loaded');
Module.onExit = function (code) {
  console.log('[miniRT] main exited with code ' + code);
};
Module.onAbort = function (what) {
  console.error('[miniRT] ABORT: ' + what);
};
Module.preRun = Module.preRun || [];
Module.preRun.push(function () {
  window.__minirtMainStarted = true;
  console.log('[miniRT] preRun — about to call main()');
});