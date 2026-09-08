extends Node

var initialized := false
var ready_sent := false
var detected_language := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		return
	# Yandex Games requirement 2.14: detect the platform language via SDK at launch.
	call_deferred("setup_yandex")

func setup_yandex() -> void:
	if not OS.has_feature("web"):
		return

	var js := """
(function () {
  if (window.__mutantMatchYandexInit) return;
  window.__mutantMatchYandexInit = true;
  window.__mutantMatchYandexReady = false;
  window.__mutantMatchYandexLang = '';

  async function initYandex() {
    try {
      const ysdk = await YaGames.init();
      window.ysdk = ysdk;
      window.__mutantMatchYandexReady = true;

      // Requirement 2.14: use the language reported by Yandex Games SDK.
      const lang = (ysdk.environment && ysdk.environment.i18n && ysdk.environment.i18n.lang)
        ? String(ysdk.environment.i18n.lang).toLowerCase()
        : '';
      window.__mutantMatchYandexLang = lang;
      console.log('Mutant Match: Yandex Games SDK language =', lang);

      // Tell the platform that the game is ready after the SDK is initialized.
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

	# YaGames.init() is asynchronous. Poll the value written by JS and apply it
	# as soon as the SDK reports the platform language.
	for i in range(300):
		var lang_value = JavaScriptBridge.eval("window.__mutantMatchYandexLang || ''", true)
		var lang := String(lang_value).strip_edges().to_lower()
		if not lang.is_empty():
			detected_language = lang
			apply_detected_language(lang)
			ready_sent = true
			return
		await get_tree().process_frame

	# If SDK is unavailable (for example, a local export), keep the game's
	# default language. On Yandex Games the SDK normally resolves long before this.
	ready_sent = true

func apply_detected_language(lang: String) -> void:
	var language_toggle = get_node_or_null("/root/LanguageToggle")
	if language_toggle == null:
		return
	if language_toggle.has_method("set_language_from_sdk"):
		language_toggle.call("set_language_from_sdk", lang)
