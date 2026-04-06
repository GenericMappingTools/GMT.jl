# Test file for broken-axis via plot() — run from the repo root:
#   julia --project=. test_brokenaxes.jl

using GMT

# ── Example 1: simple sin wave, skip the middle stretch ───────────────────
x = collect(0.0:0.05:10.0)
D1 = mat2ds([x sin.(x)])

plot(D1; breakx=(2, 8), lw=1.5, lc=:blue, region=(0, 10, -1.2, 1.2),
         xlabel="x", ylabel="sin(x)", title="Broken x-axis (breakx)")

# ── Example 2: explicit xranges, three panels ─────────────────────────────
x2 = collect(0.0:0.1:30.0)
D2 = mat2ds([x2 sin.(x2 ./ 3) .* exp.(-x2 ./ 20)])

plot(D2; xranges=[(0,4),(10,14),(24,30)], gap=0.4, lw=1, title="Three panels (xranges=)")

# ── Example 3: broken Y axis (breaky) ─────────────────────────────────────
x3 = collect(0.0:0.1:10.0)
D3 = mat2ds([x3 [fill(1.0, 61); fill(100.0, 40)]])

plot(D3; breaky=(5, 95), lw=1.5, lc=:blue, title="Broken y-axis (breaky)")

# ── Example 4: explicit yranges, three panels ─────────────────────────────
x4 = collect(0.0:0.1:10.0)
D4 = mat2ds([x4 [fill(0.0, 41); fill(50.0, 30); fill(200.0, 30)]])

plot(D4; yranges=[(-2,6),(44,56),(194,206)], gap=0.4, lw=1, title="Three y-panels (yranges=)")
