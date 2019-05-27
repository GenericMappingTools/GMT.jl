# Daylight terminators


```julia
coast(region=:global,         # Global [-180 180 -90 90]
      proj=:EckertVI,         # Projection
      resolution=:low,        # Coastline resolution
      area=5000,              # Do not plot features with area (km^2) lower than this
      borders=(1,(0.5,:gray)),# Pen settings for national borders
      water=(175,210,255),    # Ocean's color
      shore=0.5,              # Pen thicknes for coastlines
      frame=(annot=:a,ticks=:a,grid=:a))  # The frame settings
solar!(terminators=(term=:d, date="2016-02-09T16:00:00"), fill="navy@95")
solar!(terminators=(term=:c, date="2016-02-09T16:00:00"), fill="navy@85")
solar!(terminators=(term=:n, date="2016-02-09T16:00:00"), fill="navy@80")
solar!(terminators=(term=:a, date="2016-02-09T16:00:00"), fill="navy@80")
```

As one-liners (to facilitate copy-paste):

```julia
coast(region=:d, proj=:EckertVI, resolution=:low, area=5000, borders=(1,(0.5,:gray)), water=(175,210,255), shore=0.5, frame=(annot=:a,ticks=:a,grid=:a))
solar!(terminators=(term=:d, date="2016-02-09T16:00:00"), fill="navy@95")
solar!(terminators=(term=:c, date="2016-02-09T16:00:00"), fill="navy@85")
solar!(terminators=(term=:n, date="2016-02-09T16:00:00"), fill="navy@80")
solar!(terminators=(term=:a, date="2016-02-09T16:00:00"), fill="navy@80", fmt=:png, show=true)
```

```@raw html
<img src="../figs/solar.png" width="600" class="center"/>
```