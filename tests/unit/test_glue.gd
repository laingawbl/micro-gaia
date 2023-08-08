extends GutTest

func test_string_conv_ascii():
	var s: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()"
	var rt = GlueTester.RoundTripConvert(s)
	assert_eq(s, rt)
	
func test_string_conv_unicode():
	var qb: String = FileAccess.get_file_as_string("res://tests/quickbrown.txt")
	var rt = GlueTester.RoundTripConvert(qb)
	assert_eq(qb, rt)
