precision mediump float;

attribute vec3 vector;
attribute vec4 color, position;
attribute vec2 uv;

uniform mat4 model
           , view
           , projection;
uniform vec3 eyePosition
           , lightPosition;

uniform float vectorScale;

varying vec3 f_normal
           , f_lightDirection
           , f_eyeDirection
           , f_data;
varying vec4 f_color;
varying vec2 f_uv;

// Calculate the cone vertex and normal at the given index.
//
// The returned vertex is for a cone with its top at origin and height of 1.0, 
// pointing in the direction of the vector attribute.
//
// Each cone is made up of a top vertex, a center base vertex and base perimeter vertices.
// These vertices are used to make up the triangles of the cone by the following:
//   segment + 0 top vertex
//   segment + 1 perimeter vertex a+1
//   segment + 2 perimeter vertex a
//   segment + 3 center base vertex
//   segment + 4 perimeter vertex a
//   segment + 5 perimeter vertex a+1
// Where segment is the number of the radial segment * 6 and a is the angle at that radial segment.
// To go from index to segment, floor(index / 6)
// To go from segment to angle, 2*pi * (segment/segmentCount)
// To go from index to segment index, index - (segment*6)
//
vec3 getConePosition(float index, out vec3 normal) {

  const float segmentCount = 8.0;

  float segment = floor(index/6.0);
  float segmentIndex = index - (segment*6.0);

  vec3 d = vectorScale * vector;
  normal = -normalize(d);

  if (segmentIndex == 3.0) {
    return -d;
  }

  // angle = 2pi * ((segment + ((segmentIndex == 1.0 || segmentIndex == 5.0) ? 1.0 : 0.0)) / segmentCount)
  float nextAngle = float(segmentIndex == 1.0 || segmentIndex == 5.0);
  float angle = 2.0 * 3.14159 * ((segment + nextAngle) / segmentCount);

  vec3 v1 = vec3(0.0);
  vec3 v2 = v1 - d;

  vec3 u = vec3(0.0, 1.0, 0.0);
  if (u == -normal) {
    u = vec3(1.0, 0.0, 0.0);
  }
  u = normalize(cross(u, d));
  vec3 v = normalize(cross(u, d));

  vec3 x = u * cos(angle) * length(d)*0.25;
  vec3 y = v * sin(angle) * length(d)*0.25;
  vec3 v3 = v2 + x + y;
  if (segmentIndex <= 2.0) {
    vec3 tx = u * sin(angle);
    vec3 ty = v * -cos(angle);
    vec3 tangent = tx + ty;
    normal = normalize(cross(v3 - v1, tangent));
  }

  if (segmentIndex == 0.0) {
    return vec3(0.0);
  }
  return v3;
}

void main() {
  vec3 normal;
  vec3 conePosition = position.xyz + getConePosition(position.w, normal);

  vec4 m_position  = model * vec4(conePosition, 1.0);
  vec4 t_position  = view * m_position;
  gl_Position      = projection * t_position;
  f_color          = color;
  f_normal         = normal;
  f_data           = conePosition;
  f_eyeDirection   = eyePosition   - conePosition;
  f_lightDirection = lightPosition - conePosition;
  f_uv             = uv;
}