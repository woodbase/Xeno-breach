# Chromebook / Low-End Hardware Performance Notes

These settings keep Xeno Breach stable on Linux Chromebook containers and other low-end integrated GPUs.

## Renderer and project settings

- Use the Compatibility renderer (`gl_compatibility`) to avoid Vulkan dependency.
- Keep 2D/3D MSAA disabled.
- Keep SDFGI, volumetric fog, baked lightmaps, and soft shadows disabled.
- Use viewport stretch mode with keep aspect for lower internal rendering cost.
- Keep physics ticks at `60` for stable and predictable CPU cost.

## 2D texture import guidelines

For sprites and non-UI game art:

- Preferred formats: `PNG` or `WebP`
- Maximum texture size: `1024` (longest edge)
- Enable compression for non-UI textures
- Disable mipmaps for sprites
- Disable filtering for pixel-crisp sprite rendering when appropriate

Recommended sprite import options:

- `compress/mode=2`
- `mipmaps=false`
- `filter=false`

## Runtime spawn/performance caps

- Maximum enemies alive at once: `25`
- Maximum projectiles alive at once: `100`
- If a cap is reached, new spawns are skipped.

These caps intentionally prioritize frame-time stability over peak encounter density.
