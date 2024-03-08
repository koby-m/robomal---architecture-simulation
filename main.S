.global main

.include "../src/robomal.S"
.include "../src/klibio.S"

main:

	bl setupSevSeg

	mainloop:

		bl runRobomal

	b mainloop

.end
