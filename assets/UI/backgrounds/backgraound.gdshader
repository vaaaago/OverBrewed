shader_type canvas_item;
uniform float SPEED = 0.5;

void vertex() {
	// Called for every vertex the material is visible on.
	UV.x += TIME * SPEED;
	UV.y += TIME * SPEED;
}
