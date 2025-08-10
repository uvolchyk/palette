# palette

A collection of various experiments with Metal on Apple platforms.
Inspired by [sample-metal](https://github.com/dehesa/sample-metal).

Available projects:
- [Shader Exam](https://github.com/leon196/SIGExam)
- [Dissolve Effect](https://uvolchyk.me/blog/crafting-a-dissolve-effect-in-metal)
- [Harmonic Oscillation](https://uvolchyk.me/blog/oscillating-glowing-strings-with-metal-and-swiftui)

## How to run it

1. Install [mise](https://mise.jdx.dev/installing-mise.html) package manager.
```
curl https://mise.run | sh
```

2. Edit `mise.toml` configuration to run local development on device.
```
[env]
TUIST_DEVELOPMENT_TEAM = '<development team id>'
TUIST_BUNDLE_ID_PREFIX = '<project prefix>'

[tools]
tuist = "latest"
```

3. Install [tuist](https://docs.tuist.dev/es/guides/quick-start/install-tuist) build tool.
```
mise install tuist
```

4. Install project dependencies.
```
mise exec -- tuist install
```

5. Generate workspace.
```
mise exec -- tuist generate
```

If need to edit the workspace configuration
```
mise exec -- tuist edit
```

## What's inside

### MTL Quests

A series of 2D/3D experiments in Metal, where I gradually explore various aspects of graphics programming.
Listed from basics to beyond (in progress).

#### Quest #1 - Basic Triangle

Experiment: Basic Triangle Rendering \
Description: Render a single colored triangle, introduce the Metal render pipeline, vertex buffers, and per-vertex color interpolation.

#### Quest #2 - Basic Rectangle

Experiment: Animated Gradient Quad \
Description: Render a rectangle with a gradient computed from UV coordinates, and animate its color over time using uniforms.

#### Quest #3 - Basic Wireframe

Experiment: Wireframe Rendering \
Description: Render mesh wireframes without geometry shaders, using barycentric coordinates to highlight triangle edges and visualize mesh topology.

#### Quest #4 - Checkerboard

Experiment: Procedural Checkerboard \
Description: Generate and render a checkerboard pattern procedurally in the fragment shader, reinforcing mathematical texture coordinate manipulation.

#### Quest #5 - Flip Book

Experiment: Flip Book Animation \
Description: Render animated sequences using flipbook-style texture atlases, showcasing sprite animation techniques in Metal.

#### Quest #6 - Basic MVP

Experiment: Model-View-Projection (MVP) Matrices \
Description: Demonstrate how MVP matrices transform vertices from model space to screen space, visualizing the 3D transformation pipeline.

#### Quest #7 - Basic 3D

Experiment: Basic 3D Rendering \
Description: Render a colored 3D cube, animate its rotation, and introduce perspective projection and camera setup.

#### Quest #8 - UV Mapping

Experiment: UV Mapping \
Description: Illustrate how 2D texture coordinates map to 3D geometry, including texture wrapping, tiling, and basic procedural textures.

#### Quest #9 - Model Loading

Experiment: 3D Model Loading \
Description: Load and display external 3D models (e.g., OBJ files), demonstrating parsing, GPU uploads, and real-time rendering in Metal.

#### Quest #10 - Camera Rotation

Experiment: Camera Manipulation \
Description: Control and visualize camera orientation using yaw, pitch, and roll parameters, and observe their effects on 3D scene navigation.

#### Quest #11 - Basic Rotations

Experiment: Quaternion vs. Euler Rotations \
Description: Compare and animate between quaternion-based and Euler angle-based rotations, showing their behavior and differences in 3D transformations.

#### Quest #12 - Instanced Rotations

Experiment: Instanced Rotations \
Description: Display multiple objects with independent rotations, utilizing instancing and quaternion math to efficiently render and animate many objects in a scene.

#### Quest #13 - Shading

Experiment: Physically-Based Shading \
Description: Explore different shading models and light interactions, supporting dynamic lighting and material properties using Metal shading language.
