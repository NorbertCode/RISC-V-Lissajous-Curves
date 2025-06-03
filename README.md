# Lissajous Curves in RISC-V Assembly
Project made for Computer Architecture (ARKO) classes at WUT

## Parameters
The parameters $a$ and $b$ are given be the user.

Parameters set in code are $\delta$ (set to $\frac{\pi}{2}$ by default), $screensize$ (set to 512 by default) and $color$ (set to `0x00FFFFFF`, white, by default)

## Calculations
The user inputs $a$ and $b$ parameters. Then the amount of points to draw is calculated by $totalPoints = 8 \cdot screensize \cdot max(a, b)$

For each of these points the parameter $t$ is calculated like $t = \frac{currentPoint}{totalPoints} \cdot 2\pi$, which is then passed to standard equations for Lissajous curves, transformed to screen space: $x = \frac{screensize}{2} \cdot sin(at + \delta) + \frac{screensize}{2}$ and $y = \frac{screensize}{2} \cdot sin(bt) + \frac{screensize}{2}$

The sine function is approximated by using the Taylor series. The equation used here looks like: $\sum_{n=0}^{6} \frac{(-1)^n \cdot x_{norm}^{(1+2n)}}{(1+2n)!}$, where $x_{norm}$ is the angle normalized to $<-\pi, \pi>$ like $x_{norm} = x - 2\pi \cdot round(\frac{x}{2\pi})$

Finally the calculated coordinates are converted to pixel coordinates (just by converting them to integers) and then the memory address of the pixel is determined: $address = startaddress + 4((y \cdot screensize) + x)$
