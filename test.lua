local utils = require("utils");

print(utils.dump_table {
	string = "hello world",
	value = 21390,
	nested = {
		a = 1,
		b = 2,
		nesteder = {
			c = "not\ncool",
			d = 'my "quote"',
		},
	},
	empty = {},
	boolean = true,
	null = "yes\0null",
});
