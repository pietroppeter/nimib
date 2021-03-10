#remember to run also with -d:numericalDefaultStyle
import nimib, strformat, strutils
nbInit
let filename_default_style = nbDoc.filename.replace(".html", "_default_style.html")
when not defined(numericalDefaultStyle):
  nbDoc.partials["style"] = """<link rel="stylesheet" href="https://latex.now.sh/style.css">"""
  nbDoc.context["no_default_style"] = true
  # I should also change font size, see https://katex.org/docs/font.html
  let otherStyle = fmt"; _for default style [click here]({(filename_default_style.AbsoluteFile).relPath})_"
else:
  let otherStyle = fmt"; _you are looking at default style, for custom style [click here]({(nbDoc.filename.AbsoluteFile).relPath})_"

nbUseLatex
nbText: fmt"""
> This nimib example document shows how to:
>  - apply (or not) a custom style ([latex.css](https://latex.now.sh/)){otherStyle}
>  - using latex rendering of equations (thanks to [katex](https://katex.org/))
>  - having as output an html table (using standard markdown converter to table) 
>
> The document itself shows how to use [numericalnim](https://github.com/hugogranstrom/numericalnim)
> to integrate an ODE.
"""
nbText: fmt"""# Using NumericalNim

Example of usage of [numericalnim](https://github.com/hugogranstrom/numericalnim).
"""

nbCode:
  import math, numericalnim

nbText: """
## ODE

### Example 3 from [Paul's Online Notes](https://tutorial.math.lamar.edu/classes/de/eulersmethod.aspx)

We want to solve the IVP (Initial Value Problem) for this linear first order differential equation:

$$y' - y = - \frac{1}{2} e^{\frac{t}{2}} \sin(5t) + 5e^{\frac{t}{2}}\cos(5t) \qquad y(0) = 0$$

This ODE has an analytical solution:

$$y(t) = e^{\frac{t}{2}}\sin(5t)$$

We want to find the approximation to the solution and compare it with the analytical solution at $t=5$.

We will use two fixed timestep methods to find the solution:
  - Heun's 2nd order method (`Heun2`)
  - classic 4th order Runge-Kutta (`RK4`) 

As timestamps we will use $h=0.1, 0.05, 0.01$.
"""
nbText: "First we translate the ODE as $y'=f(y,t)$ with $f$:"
nbCode:
  proc f(t, y: float, ctx: NumContext[float]): float =
    y - 0.5*exp(0.5*t)*sin(5*t) + 5*exp(0.5*t)*cos(5*t)
  
  proc y(t: float): float =
    ## analytical solution
    exp(0.5*t)*sin(5*t)
  
  let y0 = 0.0
  ## we will not be using the NumContext object
  var ctx = newNumContext[float]()
  ## first derivative that will be used
  echo "y'(0): ", f(0, y0, ctx)  # "$y'(0)$" will not be converted to latex (katex has a protection not to look into code)
  ## expected solution
  let y5 = y(5)
  echo "y(5): ", y5

nbText: "We want the solution to be available for every point in $[0, 5]$ with timestep $h=0.05$"
nbCode:
  let tspan = arange(0.0, 5.0, 0.05, includeEnd=true)
  echo tspan[0 .. 2], " . . . ", tspan[^3 .. ^1]
nbText: "We compute the solution according to our selected 2 methods and 3 timesteps:"
nbCode:
  let
    options1 = newODEoptions(dt = 0.1)
    options2 = newODEoptions(dt = 0.05)
    options3 = newODEoptions(dt = 0.01)
  let
    (t1hn, y1hn) = solveODE(f, y0, tspan, options = options1, integrator = "Heun2")
    (t2hn, y2hn) = solveODE(f, y0, tspan, options = options2, integrator = "Heun2")
    (t3hn, y3hn) = solveODE(f, y0, tspan, options = options3, integrator = "Heun2")
    (t1rk, y1rk) = solveODE(f, y0, tspan, options = options1, integrator = "RK4")
    (t2rk, y2rk) = solveODE(f, y0, tspan, options = options2, integrator = "RK4")
    (t3rk, y3rk) = solveODE(f, y0, tspan, options = options3, integrator = "RK4")
  ## all returned time are the same as timespan (is this always true for fixed timestep methods?)
  assert t1hn == tspan
  assert t2hn == tspan
  assert t3hn == tspan
  assert t1rk == tspan
  assert t2rk == tspan
  assert t3rk == tspan
  ## solutions
  echo "Heun2:"
  echo y1hn[^1]
  echo y2hn[^1]
  echo y3hn[^1]
  echo "RK4:"
  echo y1rk[^1]
  echo y2rk[^1]
  echo y3rk[^1]
  echo "Analytical:"
  echo y5
nbText: "As expected Heun is not very accurate even with smaller timesteps, while Runge-Kutta is very reliable even with bigger timesteps."
nbText: "To compute percentage error of each method at $y(5)$ I will use:"
nbCode:
  proc pe(yApprox: float): string = fmt"{(100.0*abs(yApprox - y5) / abs(y5)):.3f}%"
  echo pe y1hn[^1]  ## used like this
nbText: fmt"""
The following table is built as a Markdown table in a `nbText` block.

**Table 1.** Percentage errors

Timestep | Heun2         | RK4
---------|--------------:|-------------:
$h=0.1$  | {pe y1hn[^1]} | {pe y1rk[^1]}
$h=0.05$ | {pe y2hn[^1]} | {pe y2rk[^1]}
$h=0.01$ | {pe y3hn[^1]} | {pe y3rk[^1]}

and here is the code for this Markdown block:
""" # right alignment of numbers does not seem to work. is this an issue of latex.css?
let mdCode = nbBlock.code
nbCode:
  discard
nbBlock.code = mdCode
# add a show Markdown source. It would be nice when hovering a code block to show (on the side? how to do it on mobile?) the call code (nbText: or other)
when defined(numericalDefaultStyle):
  nbDoc.filename = filename_default_style
  
nbSave
