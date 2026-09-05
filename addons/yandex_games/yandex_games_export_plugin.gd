@tool
class_name YandexGamesExportPlugin
extends EditorExportPlugin

const _TEMPLATE_PATH: String = "res://addons/yandex_games/templates/yandex_template.html"

func _get_name() -> String:
	return "YandexGamesSDK"

func _supports_platform(platform: EditorExportPlatform) -> bool:
	if platform is EditorExportPlatformWeb:
		return true
	if platform.has_method("get_os_name"):
		return platform.get_os_name() == "Web"
	return false

func _get_export_option_warning(platform: EditorExportPlatform, option: String) -> String:
	if option == "html/custom_html_shell":
		var current: String = str(get_option("html/custom_html_shell"))
		if current != _TEMPLATE_PATH:
			return "Yandex Games SDK requires this template.\nSet to: %s" % _TEMPLATE_PATH
	return ""

var _target_path: String = ""

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	if not features.has("web"):
		return
	_target_path = path
	var shell: String = str(get_option("html/custom_html_shell"))
	if shell != _TEMPLATE_PATH:
		push_error(
			"[YandexGames] Custom HTML Shell is not set to the Yandex template.\n" +
			"Go to Project → Export → Web → Options → Custom HTML Shell and select:\n" +
			_TEMPLATE_PATH
		)

func _export_end() -> void:
	if _target_path.is_empty():
		return
	var target_dir: String = _target_path.get_base_dir()
	if not target_dir.is_empty() and DirAccess.dir_exists_absolute(target_dir):
		var catalog_dst: String = target_dir.path_join("purchases-catalog.json")
		if not FileAccess.file_exists(catalog_dst):
			var catalog_content: String = ""
			if FileAccess.file_exists("res://purchases-catalog.json"):
				var f := FileAccess.open("res://purchases-catalog.json", FileAccess.READ)
				if f:
					catalog_content = f.get_as_text()
			if catalog_content.is_empty():
				catalog_content = _get_default_catalog_json()
			var out_f := FileAccess.open(catalog_dst, FileAccess.WRITE)
			if out_f:
				out_f.store_string(catalog_content)
				print("[YandexGames] Generated purchases-catalog.json in export directory for local dev proxy.")
	_target_path = ""

func _get_default_catalog_json() -> String:
	return JSON.stringify([
		{
			"id": "coins_100",
			"title": "100 Coins",
			"description": "Bag of 100 gold coins",
			"imageURI": "",
			"price": "50 YAN",
			"priceValue": "50",
			"priceCurrencyCode": "YAN",
			"getPriceCurrencyImage": ""
		},
		{
			"id": "no_ads",
			"title": "Disable Ads",
			"description": "Permanent ad removal",
			"imageURI": "",
			"price": "100 YAN",
			"priceValue": "100",
			"priceCurrencyCode": "YAN",
			"getPriceCurrencyImage": ""
		}
	], "\t")

static func configure_web_presets(presets_path: String = "res://export_presets.cfg") -> Dictionary:
	var cfg := ConfigFile.new()
	var err := cfg.load(presets_path)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		return { "success": false, "message": "Failed to load %s: error %d" % [presets_path, err] }

	var updated_count := 0
	var created := false
	var web_section_found := false

	for section in cfg.get_sections():
		if cfg.get_value(section, "platform", "") == "Web":
			web_section_found = true
			var opt_sec := section + ".options"
			var current_shell: String = str(cfg.get_value(opt_sec, "html/custom_html_shell", ""))
			if current_shell != _TEMPLATE_PATH:
				cfg.set_value(opt_sec, "html/custom_html_shell", _TEMPLATE_PATH)
				updated_count += 1

	if not web_section_found:
		var sections := cfg.get_sections()
		var idx := 0
		for s in sections:
			var n := s.trim_prefix("preset.")
			if n.is_valid_int():
				idx = max(idx, n.to_int() + 1)
		var section := "preset.%d" % idx
		cfg.set_value(section, "name", "Web (Yandex Games)")
		cfg.set_value(section, "platform", "Web")
		cfg.set_value(section, "runnable", true)
		cfg.set_value(section, "advanced_export", false)
		cfg.set_value(section, "dedicated_server", false)
		cfg.set_value(section, "export_filter", "all_resources")
		cfg.set_value(section, "include_filter", "")
		cfg.set_value(section, "exclude_filter", "")
		cfg.set_value(section, "export_path", "")
		cfg.set_value(section, "encryption_include_filters", "")
		cfg.set_value(section, "encryption_exclude_filters", "")
		cfg.set_value(section, "encrypt_pck", false)
		cfg.set_value(section, "encrypt_directory", false)

		var options_section := section + ".options"
		cfg.set_value(options_section, "html/custom_html_shell", _TEMPLATE_PATH)
		created = true

	if cfg.save(presets_path) == OK:
		var msg := ""
		if created:
			msg = "Created new Web (Yandex Games) export preset with Yandex template."
		elif updated_count > 0:
			msg = "Updated %d Web preset(s) with Yandex HTML template." % updated_count
		else:
			msg = "Web preset already configured with Yandex HTML template."
		return { "success": true, "message": msg }
	return { "success": false, "message": "Failed to save export_presets.cfg" }

static func package_to_yandex_zip(source_dir: String, output_zip: String = "") -> Dictionary:
	var abs_source := ProjectSettings.globalize_path(source_dir)
	if not DirAccess.dir_exists_absolute(abs_source):
		return { "success": false, "error": "Source directory does not exist: %s" % abs_source }

	var index_path := abs_source.path_join("index.html")
	if not FileAccess.file_exists(index_path):
		return { "success": false, "error": "index.html not found in root of %s. Yandex Games requires index.html to be at root of ZIP!" % abs_source }

	if output_zip.is_empty():
		output_zip = abs_source.path_join("yandex_game_upload.zip")
	else:
		output_zip = ProjectSettings.globalize_path(output_zip)

	var packer := ZIPPacker.new()
	var err := packer.open(output_zip)
	if err != OK:
		return { "success": false, "error": "Failed to open ZIP for writing: %s (error %d)" % [output_zip, err] }

	var add_files_recursive: Callable
	add_files_recursive = func(current_dir: String, rel_prefix: String) -> int:
		var dir := DirAccess.open(current_dir)
		if not dir:
			return 0
		var count := 0
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if file_name != "." and file_name != "..":
				var full_p := current_dir.path_join(file_name)
				var entry_rel := file_name if rel_prefix.is_empty() else rel_prefix.path_join(file_name)
				entry_rel = entry_rel.replace("\\", "/")
				if dir.current_is_dir():
					count += add_files_recursive.call(full_p, entry_rel)
				else:
					if file_name.ends_with(".zip"):
						file_name = dir.get_next()
						continue
					var f := FileAccess.open(full_p, FileAccess.READ)
					if f:
						var buf := f.get_buffer(f.get_length())
						packer.start_file(entry_rel)
						packer.write_file(buf)
						packer.close_file()
						count += 1
			file_name = dir.get_next()
		dir.list_dir_end()
		return count

	var total_files: int = add_files_recursive.call(abs_source, "")
	packer.close()

	return {
		"success": true,
		"zip_path": output_zip,
		"files_count": total_files,
		"size_bytes": FileAccess.get_file_as_bytes(output_zip).size() if FileAccess.file_exists(output_zip) else 0
	}
