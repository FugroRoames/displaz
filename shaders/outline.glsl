#version 150
// Copyright 2015, Christopher J. Foster and the other displaz contributors.
// Use of this code is governed by the BSD-style license found in LICENSE.txt

// inspired by borderlands implementation of popular "sobel filter"

// Mostly has an effect on the outline distance.
const float SampleDistance = 1.0;

uniform float Exponent = 1.0;       //# uiname=Exponent; min=0.01; max=3.0
uniform int ClipMaxDepth = 1;       //# uiname=Clip Max Depth; enum=No|Yes

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 modelViewProjectionMatrix;
uniform vec2 widthHeight;

uniform sampler2D screenTexture;
uniform sampler2D depthTexture;

//------------------------------------------------------------------------------
#if defined(VERTEX_SHADER)

in vec2 position;
in vec2 texCoord;

// Point color which will be picked up by the fragment shader
out vec2 textureCoords;

void main()
{
    textureCoords = texCoord;
    gl_Position = vec4(position, 0.0, 1.0);
}


//------------------------------------------------------------------------------
#elif defined(FRAGMENT_SHADER)

// Input texture coordinates
in vec2 textureCoords;

// Output fragment color
out vec4 fragColor;

// These aren't likely to change so we can set them as constants.
const float near = 0.05;
const float far = 500000.0;

// Convert depth buffer value to a linear range of 0.0 to 1.0.
float Linear01Depth(float depthVal)
{
    return (2.0 * near) / (far + near - depthVal * (far - near));
}

void main()
{
    float rawDepth = texture(depthTexture, textureCoords).x;
  
    // Early exit if our depth is too far back.
    float centerDepth = Linear01Depth(rawDepth);
    const float depthClipTreshold = 0.75;
    if (ClipMaxDepth > 0 && centerDepth > depthClipTreshold)
    {
        fragColor = vec4(texture(screenTexture, textureCoords).xyz, 1.0);
        return;
    }
    
    vec4 depthsDiag;
    vec4 depthsAxis;

    vec2 uvDist = SampleDistance * vec2(1.0 / widthHeight.x, 1.0 / widthHeight.y);

    depthsDiag.x = Linear01Depth(texture(depthTexture, textureCoords + uvDist).x); // TR
    depthsDiag.y = Linear01Depth(texture(depthTexture, textureCoords + uvDist * vec2(-1,1)).x); // TL
    depthsDiag.z = Linear01Depth(texture(depthTexture, textureCoords - uvDist * vec2(-1,1)).x); // BR
    depthsDiag.w = Linear01Depth(texture(depthTexture, textureCoords - uvDist).x); // BL

    depthsAxis.x = Linear01Depth(texture(depthTexture, textureCoords + uvDist * vec2(0,1)).x); // T
    depthsAxis.y = Linear01Depth(texture(depthTexture, textureCoords - uvDist * vec2(1,0)).x); // L
    depthsAxis.z = Linear01Depth(texture(depthTexture, textureCoords + uvDist * vec2(1,0)).x); // R
    depthsAxis.w = Linear01Depth(texture(depthTexture, textureCoords - uvDist * vec2(0,1)).x); // B

    depthsDiag -= centerDepth;
    depthsAxis /= centerDepth;

    const vec4 HorizDiagCoeff = vec4(1,1,-1,-1);
    const vec4 VertDiagCoeff = vec4(-1,1,-1,1);
    const vec4 HorizAxisCoeff = vec4(1,0,0,-1);
    const vec4 VertAxisCoeff = vec4(0,1,-1,0);

    vec4 SobelH = depthsDiag * HorizDiagCoeff + depthsAxis * HorizAxisCoeff;
    vec4 SobelV = depthsDiag * VertDiagCoeff + depthsAxis * VertAxisCoeff;

    float SobelX = dot(SobelH, vec4(1,1,1,1));
    float SobelY = dot(SobelV, vec4(1,1,1,1));
    float Sobel = sqrt(SobelX * SobelX + SobelY * SobelY);

    Sobel = 1.0 - pow(clamp(Sobel, 0.0, 1.0), Exponent);
    fragColor = vec4(Sobel * texture(screenTexture, textureCoords).xyz, 1.0);
}

#endif



