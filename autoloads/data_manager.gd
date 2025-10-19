extends Node

const PATH_SETTINGS := "user://settings.cfg"
const PATH_BINDINGS := "user://bindings.cfg"
const PATH_META     := "user://meta.json"
const PATH_RUN      := "user://run.json"

const META_SCHEMA_VERSION := 1
const RUN_SCHEMA_VERSION  := 1

# ---------- Public API ----------
func load_settings() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(PATH_SETTINGS)
	return cfg

func save_settings(cfg: ConfigFile) -> void:
	_save_cfg_atomic(cfg, PATH_SETTINGS)

func load_bindings() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(PATH_BINDINGS)
	return cfg

func save_bindings(cfg: ConfigFile) -> void:
	_save_cfg_atomic(cfg, PATH_BINDINGS)

func load_meta() -> Dictionary:
	return _load_json_versioned(PATH_META, META_SCHEMA_VERSION, _migrate_meta)

func save_meta(meta: Dictionary) -> void:
	meta["schema_version"] = META_SCHEMA_VERSION
	_save_json_atomic(meta, PATH_META)

func load_run() -> Dictionary:
	return _load_json_versioned(PATH_RUN, RUN_SCHEMA_VERSION, _migrate_run)

func save_run(run_state: Dictionary) -> void:
	run_state["schema_version"] = RUN_SCHEMA_VERSION
	_save_json_atomic(run_state, PATH_RUN)

func clear_run() -> void:
	if FileAccess.file_exists(PATH_RUN):
		DirAccess.remove_absolute(PATH_RUN)

# ---------- Private helpers ----------
func _load_json_versioned(path: String, expected_version: int, migrator: Callable) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"schema_version": expected_version}
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Corrupted JSON at %s, recreating." % path)
		return {"schema_version": expected_version}
	var v := int(data.get("schema_version", 0))
	while v < expected_version:
		data = migrator.call(data, v)
		v += 1
	data["schema_version"] = expected_version
	return data

func _save_json_atomic(obj: Dictionary, path: String) -> void:
	var tmp := "%s.tmp" % path
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string(JSON.stringify(obj))
	f.flush()
	f.close()
	DirAccess.remove_absolute(path) # ignore error
	DirAccess.rename_absolute(tmp, path)

func _save_cfg_atomic(cfg: ConfigFile, path: String) -> void:
	var tmp := "%s.tmp" % path
	cfg.save(tmp)
	DirAccess.remove_absolute(path)
	DirAccess.rename_absolute(tmp, path)

# ---------- Migrators ----------
func _migrate_meta(old: Dictionary, from_version: int) -> Dictionary:
	var migrated := old.duplicate(true)
	match from_version:
		0:
			# Example: rename "coins" -> "shards"
			if migrated.has("coins"):
				migrated["shards"] = migrated["coins"]
				migrated.erase("coins")
	return migrated

func _migrate_run(old: Dictionary, from_version: int) -> Dictionary:
	var migrated := old.duplicate(true)
	# Add future steps here
	return migrated
