# EE4623 PART 1 -- add Inspect immediately AFTER SDevice in SWB.
# @plot@ resolves to the upstream SDevice current filename.
# SDevice's gate sweep prepends IdVg_ to that filename.
set ProjectName "NMOS_2um"
set CurveName "IdVg(@node@)"
set GmName "gm(@node@)"
set TangentName "Tangent(@node@)"
proj_load "IdVg_@plot@" $ProjectName
cv_createDS $CurveName "$ProjectName gate OuterVoltage" \
                       "$ProjectName drain TotalCurrent" y
cv_abs $CurveName y
cv_createWithFormula $GmName "diff(<$CurveName>)" A A
set gmMax [cv_compute "vecmax(<$GmName>)" A A A A]
if {$gmMax <= 0} { error "Nonpositive gm: check contacts and the IdVg file." }
set Vgm [cv_compute "veczero(<$GmName>-$gmMax)" A A A A]
if {$Vgm <= 0.005 || $Vgm >= 4.995} {
    error "gm maximum is at a sweep boundary; inspect the curve before extracting VT0."
}
cv_createWithFormula $TangentName "tangent(<$CurveName>,$Vgm)" A A A A
set VT0 [cv_compute "vecvalx(<$TangentName>,0.0)" A A A A]
# Page 5 defines VT0 as the raw maximum-gm tangent intercept.
# Do NOT subtract VDS/2 (0.025 V) from this assignment's reported VT0.
if {$VT0 < 0.0 || $VT0 > 5.0} {
    error "Tangent intercept outside sweep; inspect the curve."
}
set Icrit [cv_compute "vecvaly(<$CurveName>,$VT0)" A A A A]
puts "VT0 (assignment maximum-gm tangent intercept) = [format %.6f $VT0] V"
puts "VGS at maximum gm = [format %.6f $Vgm] V"
puts "gmMax = [format %.6e $gmMax] (current-unit)/V"
puts "ICRIT = [format %.6e $Icrit] (same current unit as SDevice output)"
ft_scalar VT0 [format %.6f $VT0]
ft_scalar Vtgm [format %.6f $VT0]
ft_scalar gmMax [format %.6e $gmMax]
ft_scalar Vgm [format %.6f $Vgm]
ft_scalar Icrit [format %.6e $Icrit]
cv_display $CurveName y
cv_display $GmName y2
cv_display $TangentName y
gr_setAxisAttr X {Gate voltage (V)} 12 {} {} black 1 10 0 5 0
gr_setAxisAttr Y {Drain current (SDevice output units)} 12 {} {} black 1 10 0 5 0
gr_setAxisAttr Y2 {Transconductance (current-unit/V)} 12 {} {} black 1 10 0 5 0
set fp [open "n@node@_VT0_results.txt" w]
puts $fp "Lgate_um=2.0; VDS_V=0.05; VBS_V=0; Temperature_K=300"
puts $fp "VT0_V=$VT0"
puts $fp "Vgm_V=$Vgm"
puts $fp "gmMax=$gmMax"
puts $fp "Icrit=$Icrit"
close $fp
