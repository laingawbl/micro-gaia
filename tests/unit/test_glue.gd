extends GutTest

func test_string_conv_ascii():
	var s: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()"
	var rt = GlueTester.RoundTripConvert(s)
	assert_eq(s, rt)
	
func test_string_conv_unicode():
	var qb: String = FileAccess.get_file_as_string("res://tests/quickbrown.txt")
	var rt = GlueTester.RoundTripConvert(qb)
	assert_eq(qb, rt)

func test_string_conv_astral():
	var ap: String = '🌕𝐀𝓑𝛱𝟞👍🏼'
	var rt = GlueTester.RoundTripConvert(ap)
	assert_eq(ap, rt)
	
func test_config_map_basic():
	var cf: ConfigFile = ConfigFile.new()
	cf.set_value("foo", "bar", 12)
	cf.set_value("baz", "qux", "hello")
	cf.set_value("non", "existent", true)
	cf.set_value("non", "existent", null)
	GlueTester.ConvertAndPrintConfigFile(cf)
	pass_test('It didn\'t throw anything great')
