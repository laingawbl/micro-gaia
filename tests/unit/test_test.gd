extends GutTest

# this is a notional test of the testing system, how perverse

func before_each():
	gut.p("ran setup", 2)

func after_each():
	gut.p("ran teardown", 2)

func before_all():
	gut.p("ran run setup", 2)

func after_all():
	gut.p("ran run teardown", 2)

func test_adder():
	assert_eq(Adder.Add(42, 13), 55, "Adder should add two numbers wow")
