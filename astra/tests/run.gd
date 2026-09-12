extends SceneTree

func _initialize() -> void:
	var failures: Array[String]=[]
	var suites=["core_test","powers_test","ai_test","diagnostics_test"]
	for name in suites:
		var path="res://tests/"+name+".gd"
		if not ResourceLoader.exists(path):
			failures.append("Missing suite: "+name)
			continue
		var suite=load(path)
		if suite==null or not suite.has_method("run"):
			failures.append("Invalid suite: "+name)
			continue
		var result: Array=suite.run()
		for error in result: failures.append(name+": "+str(error))
		print("%s: %s" % [name,"PASS" if result.is_empty() else "FAIL"])
	for failure in failures: printerr(failure)
	print("Astra: %d suite(s), %d failure(s)" % [suites.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
