extends Node

var initialized := false
var ready_sent := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		return
	call_deferred("setup_yandex")

func setup_yandex() -> void:
	# Wait until the start screen is actually visible and interactive.
	for i in range(120):
		var start_screen = get_node_or_null("/root/StartScreen")
		if start_screen != null:
			var overlay = start_screen.get("overlay")
			if overlay != null and is_instance_valid(overlay):
				break
		await get_tree().process_frame

	if not OS.has_feature("web"):
		return

	var js := """
(function () {
  if (window.__mutantMatchYandexInit) return;
  window.__mutantMatchYandexInit = true;

  async function initYandex() {
    try {
      const ysdk = await YaGames.init();
      window.ysdk = ysdk;
      window.__mutantMatchYandexReady = true;
      if (ysdk.features && ysdk.features.LoadingAPI && ysdk.features.LoadingAPI.ready) {
        ysdk.features.LoadingAPI.ready();
      }
      console.log('Mutant Match: Yandex Games SDK initialized');
    } catch (e) {
      console.error('Mutant Match: Yandex Games SDK init failed', e);
    }
  }

  if (typeof YaGames !== 'undefined') {
    initYandex();
    return;
  }

  const script = document.createElement('script');
  script.src = '/sdk.js';
  script.async = true;
  script.onload = initYandex;
  script.onerror = function () {
    console.warn('Mutant Match: /sdk.js is unavailable outside Yandex Games hosting');
  };
  document.head.appendChild(script);
})();
"""
	JavaScriptBridge.eval(js, true)
	initialized = true
	ready_sent = true
