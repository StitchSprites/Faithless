#version 150

#moj_import <depth_utils.glsl>

const vec2 corners[4] = vec2[4](vec2(0), vec2(0, 1), vec2(1), vec2(1, 0));

bool Between(float v, float min, float max) { return (min < v) && (v < max); }

// -- Generic Vertex Functions --------------------------------------------------------------------------------------

mat3 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

vec3 chunk_quad_fade(vec3 ModelOffset, vec3 Normal, vec3 Position, float FogEnd, int vertIndex) {
    vec3 fractPosition = fract(Position), absNormal = abs(Normal);
    
    if (absNormal.x == 1.0) fractPosition *= rotationMatrix(Normal.zxy, -1.570796); 
    else if (absNormal.y == 1.0) fractPosition *= rotationMatrix(Normal.yzx, 1.570796); 
    else if (Normal.z == -1.0) fractPosition *= rotationMatrix(Normal.yzx, -3.14159);
    
    vec3 originOffset = vec3(
        (fractPosition.x > 0.001 && fractPosition.x < 0.999) ? 0.5 - fractPosition.x : 0.5,
        (fractPosition.y > 0.001 && fractPosition.y < 0.999) ? 0.5 - fractPosition.y : 0.5,
        0.0
    );

    if ((vertIndex == 0 || vertIndex == 3) && originOffset.y == 0.5) originOffset.y *= -1.0;
    if ((vertIndex == 2 || vertIndex == 3) && originOffset.x == 0.5) originOffset.x *= -1.0;

    if (absNormal.x == 1.0) originOffset *= rotationMatrix(Normal.zxy, 1.570796);
    else if (absNormal.y == 1.0) originOffset *= rotationMatrix(Normal.yzx, -1.570796);
    else if (Normal.z == -1.0) originOffset *= rotationMatrix(Normal.yzx, 3.14159);
    
    float distXZ = length(vec2(Position.x + ModelOffset.x, Position.z + ModelOffset.z));  // Only consider X and Z distances
    float fadeAmount = pow(max(0.0, distXZ - (FogEnd - 16.0)), 2.0);    
    return clamp(fadeAmount * 0.075 / 16.0, 0.0, 1.0) * originOffset;
}

vec3 chunk_polygon_fade(vec3 ModelOffset, vec3 Normal, vec3 Position, float FogEnd, int vertIndex) {
    vec3 fractPosition = fract(Position), absNormal = abs(Normal);
    
    if (absNormal.x == 1.0) fractPosition *= rotationMatrix(Normal.zxy, -1.570796); 
    else if (absNormal.y == 1.0) fractPosition *= rotationMatrix(Normal.yzx, 1.570796); 
    else if (Normal.z == -1.0) fractPosition *= rotationMatrix(Normal.yzx, -3.14159);
    
    vec3 originOffset = vec3(
        (fractPosition.x > 0.001 && fractPosition.x < 0.999) ? 0.5 - fractPosition.x : 0.5,
        (fractPosition.y > 0.001 && fractPosition.y < 0.999) ? 0.5 - fractPosition.y : 0.5,
        0.0
    );

    if ((vertIndex == 0 || vertIndex == 3) && originOffset.y == 0.5) originOffset.y *= -1.0;
    if ((vertIndex == 2 || vertIndex == 3) && originOffset.x == 0.5) originOffset.x *= -1.0;

    if (absNormal.x == 1.0) originOffset *= rotationMatrix(Normal.zxy, 1.570796);
    else if (absNormal.y == 1.0) originOffset *= rotationMatrix(Normal.yzx, -1.570796);
    else if (Normal.z == -1.0) originOffset *= rotationMatrix(Normal.yzx, 3.14159);
    
    float distXZ_squared = (Position.x + ModelOffset.x) * (Position.x + ModelOffset.x) + (Position.z + ModelOffset.z) * (Position.z + ModelOffset.z);    
    float fadeAmount = pow(max(0.0, distXZ_squared - (FogEnd - 16.0) * (FogEnd - 16.0)), 2.0);    
    return clamp(fadeAmount * 0.075 / 16.0, 0.0, 1.0) * originOffset;
}

float chunk_translate(vec3 ModelOffset, float fogEnd) {
    float dx = ModelOffset.x + 8.0, dz = ModelOffset.z + 8.0;    
    float factor = max((dx * dx + dz * dz) / (fogEnd * fogEnd) - 1.0, 0.0);    
    return factor * factor * -4000.0;
}

// -- Orthographic View --------------------------------------------------------------------------------------

// 26.2: the depth range comes from the active projection (reversed Z, [-1,1] or [0,1]) instead of assuming the
// classic OpenGL one, so depth testing keeps working with the orthographic view.
mat4 getOrthoMat(mat4 ProjMat, float Zoom) {
    bool reversed = projection_is_reversed(ProjMat);
    bool zeroToOne = projection_is_zero_to_one(ProjMat);

    // NDC depth of the near / far planes in the active convention
    float ndcNear = reversed ? 1.0 : (zeroToOne ? 0.0 : -1.0);
    float ndcFar  = reversed ? (zeroToOne ? 0.0 : -1.0) : 1.0;

    // Distance of the far plane, recovered from ProjMat (an infinite far plane falls back to a fixed distance)
    float farDenom = ndcFar + ProjMat[2][2];
    float far = abs(farDenom) > 1.0e-5 ? abs(ProjMat[3][2] / farDenom) : 2048.0;
    far = clamp(far, 16.0, 8192.0);

    float nearDist = 1000.0;     // the view volume starts this far behind the camera
    float fixed_near = 0.05; 
    
    float left = -(0.5 / (ProjMat[0][0] / (2.0 * fixed_near))) / Zoom;
    float right = -left;
    float top = (0.5 / (ProjMat[1][1] / (2.0 * fixed_near))) / Zoom;
    float bottom = -top;

    // linear depth map: eye z = +nearDist -> ndcNear, eye z = -far -> ndcFar
    float zScale = (ndcFar - ndcNear) / (-far - nearDist);
    float zBias = ndcNear - zScale * nearDist;

    return mat4(2.0 / (right - left),               0.0,                                0.0,                            0.0,
                0.0,                                2.0 / (top - bottom),               0.0,                            0.0,
                0.0,                                0.0,                                zScale,                         0.0,
                -(right + left) / (right - left),   -(top + bottom) / (top - bottom),   zBias,                          1.0);
}

float getPlayerYaw(mat4 modelViewMat) {
    vec3 forward = normalize(vec3(modelViewMat[2][0], 0.0, modelViewMat[2][2]));
    return degrees(atan(forward.z, forward.x));
}

mat4 getIsometricViewMat(mat4 modelViewMat) {
    float playerYaw = getPlayerYaw(modelViewMat);

    float snappedYaw;
    float angle45 = 45.0;
    float angle225 = 225.0;

    if (abs(playerYaw - 45.0) < 180.0) {
        snappedYaw = 45.0;
    } else if (abs(playerYaw - 45.0) >= 180.0) {
        snappedYaw = 225.0;
    }

    float angleY = radians(snappedYaw);

    mat4 rotY = mat4(
        cos(angleY), 0.0, sin(angleY), 0.0,
        0.0, 1.0, 0.0, 0.0,
        -sin(angleY), 0.0, cos(angleY), 0.0,
        0.0, 0.0, 0.0, 1.0
    );

    float angleX = radians(-35.264);
    mat4 rotX = mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, cos(angleX), -sin(angleX), 0.0,
        0.0, sin(angleX), cos(angleX), 0.0,
        0.0, 0.0, 0.0, 1.0
    );

    mat4 isometricViewMat = rotX * rotY;
    isometricViewMat[3] = modelViewMat[3];
    return isometricViewMat;
}
