extends SceneTree

func _init() -> void:
	print("========================================")
	print("       ISLAND EMPIRE TEST RUNNER       ")
	print("========================================")

	var test_files = [
		"res://tests/unit/test_economy.gd",
		"res://tests/unit/test_combat.gd",
		"res://tests/unit/test_age_progression.gd",
		"res://tests/unit/test_factions_and_units.gd",
		"res://tests/unit/test_ui_system.gd"
	]

	var total_tests: int = 0
	var passed_tests: int = 0
	var failed_tests: int = 0

	for path in test_files:
		var script = load(path)
		if not script:
			print("❌ Could not load test script: ", path)
			failed_tests += 1
			continue

		var suite = script.new()
		print("\nRunning Suite: ", path.get_file().get_basename())

		# Look for methods starting with test_
		for m in suite.get_method_list():
			var name: String = m["name"]
			if name.begins_with("test_"):
				total_tests += 1
				var res = run_single_test(suite, name)
				if res["ok"]:
					print("  ✅ PASS: ", name)
					passed_tests += 1
				else:
					print("  ❌ FAIL: ", name, " -> ", res["msg"])
					failed_tests += 1

		if suite is Node:
			suite.queue_free()

	print("\n========================================")
	print("Test Results: %d Passed, %d Failed, %d Total" % [passed_tests, failed_tests, total_tests])
	print("========================================")

	if failed_tests > 0:
		quit(1)
	else:
		quit(0)

func run_single_test(suite: Object, method_name: String) -> Dictionary:
	if suite.has_method("setup"):
		suite.call("setup")

	var result = suite.call(method_name)

	if suite.has_method("teardown"):
		suite.call("teardown")

	if result is Dictionary and result.has("passed") and not result["passed"]:
		return {"ok": false, "msg": result.get("message", "Assertion failed")}
	return {"ok": true, "msg": ""}
