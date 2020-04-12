# julia_brot

Explore the mandelbrot and julia sets

## Requirements

- `jdk-11.0.3+`
- `jruby-9.2.11.1+`
- `propane-3.5.0 gem`

Since propane-3.5.0 reflective access warning should be gone

## Start

Navigate to directory containing julia_brot.rb and run:

`jruby --dev julia_brot.rb` # --dev speeds startup

## Controls

Use control panel sliders to adjust center, zoom
Use control panel button to reset to original Mandelbrot
Use check box to adjust precision
Use menu to select static julia

Mandelbrot View Only:
- Left Click: view the julia set of the seed clicked in mandelbrot
- Right Click: starting seed of a julia loop animation. a red line will be drawn to your mouse position, click again for an animated loop between the starting and ending julia seeds
