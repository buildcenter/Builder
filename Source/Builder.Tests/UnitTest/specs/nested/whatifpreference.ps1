task default -depends WhatIfCheck

task WhatIfCheck {
	assert ($p1 -eq 'whatifcheck') ('Expect $p1 to be "whatifcheck" (actual value is "{0}")' -f $p1) 
}
