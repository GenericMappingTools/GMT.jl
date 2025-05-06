# Modified from the ERA5Reanalysis.jl package
Dict(
"u" => ["u_component_of_wind", "Zonal Wind", "m s**-1"],
"v" => ["v_component_of_wind", "Meridional Wind", "m s**-1"],
"w" => ["vertical_velocity", "Vertical Wind", "Pa s**-1"],
"t" => ["temperature", "Temperature", "K"],
"z" => ["geopotential", "Pressure Level Geopotential", "m**2 s**-2"],
"d" => ["divergence", "Divergence", "s**-1"],
"vo" => ["vorticity", "Vorticity (Relative)", "s**-1"],
"pv" => ["potential_vorticity", "Potential Vorticity", "K m**-2 kg**-1 s**-1"],
"r" => ["relative_humidity", "Relative Humidity", "%"],
"q" => ["specific_humidity", "Specific Humidity", "kg kg**-1"],
"cc" => ["fraction_of_cloud_cover", "Cloud Cover Fraction", "%"],
"ciwc" => ["specific_cloud_ice_water_content", "Specific Cloud Ice Water Content", "kg kg**-1"],
"clwc" => ["specific_cloud_liquid_water_content", "Specific Cloud Liquid Water Content", "kg kg**-1"],
"crwc" => ["specific_rain_water_content", "Specific Rain Water Content", "kg kg**-1"],
"cswc" => ["specific_snow_water_content", "Specific Snow Water Content", "kg kg**-1"],
"o3" => ["ozone_mass_mixing_ratio", "Ozone Mass Mixing Ratio", "kg kg**-1"]
)
