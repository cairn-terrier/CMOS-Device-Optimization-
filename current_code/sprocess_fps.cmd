# EE4623 PART 1 -- 2 um NMOS baseline (SENTAURUS PROCESS / SWB)
# Paste this entire file into the original project's SProcess command editor.
# SWB table: Domain=NMOS, Lgate=2.0 (um); delete/disable the PMOS experiments.
# Add tempOx=1000.0 (C), timeOx=30.0 (min): UNCALIBRATED oxidation trial.
# Keep CMOS130_lyt.mac and the original split/tool setup in the project folder.
# Other defaults are local fset variables below.
# This file builds a device. Run the supplied SDevice and Inspect files for VT0.
# Expected VT0 ~0.7--0.8 V is a comparison target, NOT a simulation input.
# Process choices not specified in green are documented in README.md.

#header

# NMOS only. In the SWB table keep ONE experiment: Domain=NMOS, Lgate=2.0.
set Type NMOS

icwb filename= "CMOS130_lyt.mac" scale= 1e-3

fset Domains [icwb list domains]
icwb domain= "@Domain@"

#rem # Query utility: Returns the dimension of the selected simulation domain.
fset DIM [icwb dimension]

#rem # Define stretch marks.
icwb stretch name= "${Type}_L" value= @<(Lgate-0.060)>@


#rem # Query utility: Returns the bounding box of the simulation
fset Ymin [icwb bbox left ]
fset Ymax [icwb bbox right]
fset Zmin [icwb bbox back ]
fset Zmax [icwb bbox front]
LogFile "icwb: Centered Bounding Box: Ymin -> $Ymin ; Ymax -> $Ymax ; Zmin -> $Zmin ; Zmax -> $Zmax"

fset LYmin [icwb bbox ymin]
fset LYmax [icwb bbox ymax]
LogFile "icwb: Layout Bounding Box -> Lymin -> $LYmin ;  Lymax -> $LYmax"

fset Ymid [expr ($Ymax+$Ymin)/2.0]
set CNode @node@

#endheader

icwb.create.all.masks info=1

#rem #---------------------------------------------------------------------#
#rem #   DESIGN RULES
#rem #---------------------------------------------------------------------#
fset PolyPitch 0.32
fset Tpoly     0.16
fset IsoPitch  0.345

#rem #---------------------------------------------------------------------#
#rem #   PARAMETERS
#rem #---------------------------------------------------------------------#

fset Lg  @Lgate@
fset Lg2 @<Lgate/2.0>@

fset PolyReox 0.005
# Assignment TARGET: 300 Angstrom = 30 nm = 0.030 um; measure actual tox.
fset gox 0.030
fset Nsub 1.35e15
fset Qvt  2.0e12
fset Evt  30.0
# REQUIRED: thermally grow the gate oxide in O2.
# Add SWB parameters tempOx (C) and timeOx (min).
# Starting trial ONLY: tempOx=1000.0, timeOx=30.0.
# Calibrate timeOx until the MEASURED channel oxide is 0.030 um.
# gox is a geometry target; it does not prescribe the grown oxide thickness.
fset tempOx @tempOx@
fset timeOx @timeOx@
# Inherited source/drain implant: not an assignment green-highlighted default.
fset Qsd 5.5e15
fset Esd 55.0
fset SiRecess 0.005
fset Lsp 0.035
fset Tsub 10.0
 
fset Nat_oxide   0.002
fset Metal1      0.15
fset Divot       0.01

fset STI_depth   0.45
fset STI_tilt    87.0
fset VIA_tilt    82.0
fset CoSi_thick  0.020

#rem #---------------------------------------------------------------------#
#rem #   SIMULATION CONTROLL
#rem #---------------------------------------------------------------------#
fset fp    1.0
fset FastMode 0
fset debug 0
fset count 1
fset MinNormalSize 0.005
fset NormalGrowthRatio 2.0

fproc WriteBND {} {
        global count
        global CNode
        
        if { $count < 10} {
          struct tdr.bnd=n${CNode}_0${count} 
        } else {
          struct tdr.bnd=n${CNode}_${count} 
        }
        incr count
}

#rem # Parallel simulation strategy and unified coordinate system
math numThreads= 8
math coord.ucs

#rem #---------------------------------------------------------------------#
#rem #   START SIMULATION 
#rem #---------------------------------------------------------------------#
line x location= -0.1
line x location= 0.0 tag= top
line x location= 0.1 
line x location= $Tsub tag= bottom

line y location= $Ymin   spacing= 100.0 tag= left
line y location= $Ymid   spacing= 100.0 tag= right

region Silicon substrate xlo= top xhi= bottom ylo= left yhi= right
init Silicon field= Boron concentration= $Nsub wafer.orient= {0 0 1} flat.orient= {1 1 0} slice.angle= 45 !DelayFullD
refinebox interface.materials= {Silicon PolySilicon Oxide}

AdvancedCalibration

# pdb settings ---------------------------------------------------------
pdbSet InfoDefault 1
pdbSet Diffuse minT 500.0 
pdbSet Mechanics StressHistory 1
pdbSet Mechanics EtchDepoRelax 0

pdbSet ImplantData ResistSkip 1
pdbSet ImplantData LeftBoundary Reflect
pdbSet ImplantData RightBoundary Reflect
pdbSet ImplantData BackBoundary Reflect
pdbSet ImplantData FrontBoundary Reflect

# meshing strategy ----------------------------------------------------------------------
grid set.min.normal.size= $MinNormalSize/$fp \
     set.normal.growth.ratio.2d= $NormalGrowthRatio \
     set.max.points= 10000000 set.max.neighbor.ratio= 1e6

## ----------- STI --------------------------
deposit material= {Oxide}   type= anisotropic  rate= {1.0} time= 0.01
deposit material= {Nitride} type= anisotropic  rate= {1.0} time= 0.1

photo mask= Active_n thickness= 0.2
if { $debug } { WriteBND }

etch material= {Nitride} type= anisotropic rate= {0.1} time= 1.1
strip Photoresist
if { $debug } { WriteBND }

etch material= {Oxide} type= anisotropic rate= {0.01} time= 1.1
if { $debug } { WriteBND }

etch material= {Silicon} type= trapezoidal rate= $STI_depth time= 1.0 angle= $STI_tilt
if { $debug } { WriteBND }

temp_ramp name= liner time= 5  temp= 600.0 ramprate= 0.6667
temp_ramp name= liner time= 10 temp= 800.0 hold
temp_ramp name= liner time= 5  temp= 800.0 ramprate= -0.6667

if { $FastMode != 1  } {
diffuse stress.relax temp_ramp= liner info= 1
}

strip nitride
strip oxide
if { $debug } { WriteBND }

etch    material= {Silicon} type= isotropic rate= {0.005} time= 1.0
deposit material= {Silicon} type= isotropic rate= {0.005} time= 1.0
if { $debug } { WriteBND }

deposit material= {Oxide} type= fill  coord= -0.002
if { $debug } { WriteBND }

refinebox name= Vt mask= Active_p \
 extend= 0.015 extrusion.min= -0.001 extrusion.max= 1.5 \
 xrefine= "0.005 0.02/$fp" yrefine= "$PolyPitch/(25.0*$fp)" zrefine= "$IsoPitch/(20.0*$fp)"

grid remesh

## ---------- Single NMOS threshold-adjust implant -----------------------
# The p-type substrate supplies the body; no extra deep p-well implant.
# Dose in cm^-2, energy in keV. Keep FastMode=0 for electrical results.
photo mask= pWELL_n thickness= 1.0
if { $debug } { WriteBND }
if { $FastMode != 1 } {
implant Boron dose= $Qvt energy= $Evt tilt= 0.0
}
strip Photoresist

# Simplified activation using the original well anneal's peak hold.
# This thermal budget is inherited, not specified by the assignment.
if { $FastMode != 1 } {
diffuse stress.relax time= 20<s> temp= 1050<C>
}

# -------------------------------------------------------------------- #
SetPlxList { BTotal PTotal }
WritePlx n@node@_well.plx y= $Ymid
# -------------------------------------------------------------------- #

etch material= {Oxide} type= anisotropic  rate= {(0.001+$Divot)*0.8} time= 1.0 
etch material= {Oxide} type= isotropic    rate= {(0.001+$Divot)*0.2} time= 1.0
if { $debug } { WriteBND }

#split @Poly@

## ---------- Gate oxide: thermal growth in pure O2 ----------------------
# One oxidation command; no gate-oxide deposition or inert substitute.
# O2 is pure oxygen at 1 atm. Temperature is C; time is minutes.
# Actual thickness is a simulation OUTPUT, to be calibrated to 30 nm.
diffuse temperature= $tempOx<C> time= $timeOx<min> O2
struct tdr= n@node@_gateoxide
if { $debug } { WriteBND }

## ---------- poly silicon deposition and etching ---------------
deposit material= {Poly} type= isotropic  thickness= $Tpoly
if { $debug } { WriteBND }

photo mask= POLY_n thickness= 0.2
if { $debug } { WriteBND }

etch  material= {Poly} type= anisotropic rate= $Tpoly+$gox time= 1.0
if { $debug } { WriteBND }

strip Photoresist
if { $debug } { WriteBND }

etch    material= {Poly} type= isotropic rate= {0.005} time= 1.0
deposit material= {Poly} type= isotropic rate= {0.005} time= 1.0 selective.materials= {Poly}
if { $debug } { WriteBND }

## ---------- Si recess etching (near poly-gate) ----------------------------
etch material= {Oxide} type= anisotropic rate= $gox time= 1.0
etch material= {Silicon} type= trapezoidal rate= $SiRecess time= 1.0 angle= 45.0
if { $debug } { WriteBND }

## ---------- reoxidation -----------------------------------------
deposit material= {Oxide} type= isotropic rate= {1.0} time= $PolyReox
if { $debug } { WriteBND }

temp_ramp name= polyreox time= 0.0667 temp= 600.0 ramprate= 50.0
temp_ramp name= polyreox time= 0.0667 temp= 800.0 ramprate= 25.0
temp_ramp name= polyreox time= 0.0833 temp= 900.0 ramprate=  0.0
temp_ramp name= polyreox time= 0.0667 temp= 900.0 ramprate= -25.0
temp_ramp name= polyreox time= 0.0667 temp= 800.0 ramprate= -50.0

if { $FastMode != 1  } {
diffuse stress.relax temp_ramp= polyreox
}

#split @Ext@

## Meshing 
refinebox name= HALO mask= Active_p \
 extend= 0.01 extrusion.min= -0.05 extrusion.max= 0.15 \
 xrefine= "0.004/$fp"  yrefine= "$PolyPitch/(100.0*$fp)" zrefine= "$IsoPitch/(60.0*$fp)" 
 
refinebox name= YEXT mask= Mesh_EXT_p \
 extend= 0.002 extrusion.min= -$gox extrusion.max= 0.035 \
 xrefine= "0.001/$fp"  yrefine= "0.0015/$fp" zrefine= "$IsoPitch/(60.0*$fp)" Silicon 

refinebox name= EXT_IF mask= Active_p \
 extend= 0.005 extrusion.min= -3*$gox extrusion.max= 0.006 \
 min.normal.size= 0.0002/$fp normal.growth.ratio= 1.5 \
 interface.materials = {Silicon Oxide PolySilicon Oxide} 

grid remesh

## ---------- Halo and LDD disabled for the initial baseline -------------
# The following original NMOS steps are intentionally commented out.
# photo mask= pWELL_n thickness= 0.5
# implant Boron dose= 8.0e12 energy= 25.0 tilt= 30 rotation= 0
# implant Boron dose= 8.0e12 energy= 25.0 tilt= 30 rotation= 90
# implant Boron dose= 8.0e12 energy= 25.0 tilt= 30 rotation= 180
# implant Boron dose= 8.0e12 energy= 25.0 tilt= 30 rotation= -90
# implant Arsenic dose= 2.65e15 energy= 6.0 tilt= 0.0
# strip Photoresist
# diffuse time= 1.5<s> temp= 1000<C>
# All PMOS halo / extension operations have been removed.

#split @SD@

## ---------- side wall spacer -----------------------------------
deposit material= {Nitride} type= isotropic  rate= {1.0} time= $Lsp
if { $debug } { WriteBND }

deposit material= {Oxide} type= isotropic  rate= {1.0} time= 1.2*$Lsp
if { $debug } { WriteBND }

etch material= {Oxide Nitride} type= anisotropic rate= {1.5*$Lsp 1.5*$Lsp} time= 2.0 force.full.levelset
if { $debug } { WriteBND }

deposit material= {Oxide} type= isotropic  rate= $Nat_oxide time= 1.0 temperature= 500<C>
if { $debug } { WriteBND }

## ---------- HDD implantation -----------------------
photo mask= pWELL_n thickness= 0.5
if { $debug } { WriteBND }

if { $FastMode != 1  } {
implant Arsenic dose= $Qsd energy= $Esd tilt= 0.0 rotation= 0.0
}

strip Photoresist
if { $debug } { WriteBND }

# PMOS HDD implant removed: NMOS-only baseline.

struct tdr= n@node@_asImpHDD

diffuse time= 1.5<s> temp= 1000<C>

# -------------------------------------------------------------------- #
SetPlxList { BTotal AsTotal PTotal}
WritePlx n@node@_anneal.plx y= [expr $Ymid-($Lg2-0.01)]
# -------------------------------------------------------------------- #

#split @Silicide@

etch material= {Oxide Nitride} type= isotropic  rate= {$Nat_oxide $Nat_oxide} time= 1.45 
if { $debug } { WriteBND }

etch material= {Silicon} type= isotropic rate= {0.008} time= 1.0 
if { $debug } { WriteBND }

# Ramp-up from RT
diffuse stress.relax time= 60<s>  temperature= 20<C> ramprate= [ expr (500.0 - 20.0)/60.0 ]<C/s> 

deposit material= {CobaltSilicide} type= isotropic rate= $CoSi_thick time= 1.0 temperature= 500 selective.materials= {Silicon}
if { $debug } { WriteBND }

deposit material= {Oxynitride} type= isotropic rate= 0.05 time= 1.0 steps= 6 temperature= 500
deposit material= {Oxide} type= fill coord= -$Metal1-0.1
if { $debug } { WriteBND }

# Ramp-down
diffuse stress.relax time= 60<s> temperature= 500<C>  ramprate= [ expr (20.0 - 500.0)/60.0 ]<C/s>

#split @Contact@

photo mask= VIA1_p thickness= 0.5
if { $debug } { WriteBND }

etch material= { Oxide } type= trapezoidal thickness= 1.65*$Metal1 angle= $VIA_tilt
if { $debug } { WriteBND }
etch material= { Oxynitride } type= trapezoidal thickness= 1.65*$Metal1 angle= $VIA_tilt
if { $debug } { WriteBND }

strip Photoresist
if { $debug } { WriteBND }

deposit material= { Tungsten } type= fill coord= -$Metal1-0.1+0.001
if { $debug } { WriteBND }

refinebox name= Trench mask= VIA1_p \
 extend= 0.0 extrusion.min= -2*$Metal1 extrusion.max= 0.001 \
 min.normal.size= 0.001/$fp normal.growth.ratio= 2.0 \
 interface.materials = {Oxide Tungsten Oxynitride Tungsten}

#split @DeviceMesh@

# Mesh Multiplication factor for device
fset fd 1.0
# Keep the full substrate. The original 0.5 um body cut is too shallow
# to assume harmless for this lightly doped long-channel baseline.
fset Xbot $Tsub

# Truncate Top-bottom
transform cut min= {-10 -10 -10} max= {$Xbot 10 10}
# Preserve dielectric regions, including the gate oxide, in the device mesh.
# strip Oxide
strip Tungsten
strip Aluminum
strip Oxynitride

##---------------Remeshing for device simulation--------##
# clear the process simulation mesh
refinebox clear
line clear

# Set very high values for adaptive meshing parameters
pdbSet Grid AdaptiveField Refine.Abs.Error 1e37
pdbSet Grid AdaptiveField Refine.Rel.Error 1e10
pdbSet Grid AdaptiveField Refine.Target.Length 100.0

# Set high quality meshes
grid Adaptive set.Delaunay.type= boxmethod \
     set.max.points= 1000000 \
     set.max.neighbor.ratio= 1e6 \
     set.min.normal.size= 0.01/$fd \
     set.normal.growth.ratio.2d= 4.0

# Refinement strategy
refinebox name= Device_Bulk min= {0.0 $Ymin} max= {$Xbot $Ymid} \
    xrefine= 0.25 yrefine= 0.1 Silicon

refinebox name= Device_Active mask= Active_p \
 	extend= 0.01 extrusion.min= -$Tpoly extrusion.max= 0.3 \
 	refine.fields= { NetActive } def.max.asinhdiff= 1.0 \
        refine.max.edge= " 0.01/$fd     $PolyPitch/(20*$fd)   $IsoPitch/(16.0*$fd)" \
        refine.min.edge= " 0.0025/$fd   $PolyPitch/(80*$fd)   $IsoPitch/(64.0*$fd)" \
        materials= {Silicon PolySilicon} adaptive
	
refinebox name= Device_Ext mask= Mesh_EXT_p \
 	extend= 0.01 extrusion.min= -0.01 extrusion.max= 0.04 \
 	xrefine= 0.002/$fd  yrefine= 0.002/$fd zrefine= $IsoPitch/(20.0*$fd) materials= {Silicon}

refinebox name= Device_IF mask= Active_p \
        extend= 0.005 extrusion.min= -($gox+0.01) extrusion.max= 0.04 \
        min.normal.size= 0.0002/$fd normal.growth.ratio= 1.2 \
        interface.mat.pairs= {Silicon Oxide PolySilicon Oxide} 
        	
grid remesh 

# Constant Poly Doping and Contact
term name=NetActive PolySilicon delete

# Explicit n+ polysilicon gate retained from the source template.
# Trial depth: 0.010 um = 10 nm.
# Confirm this point lies inside the source-side CobaltSilicide.
set SilicideX 0.010
select z= "1.5e20" name= NetActive store PolySilicon

# Contacts
icwb.contact.mask layer.name= "GATE" name= gate box PolySilicon xlo= -$Tpoly-$gox-0.05 xhi= -$Tpoly-$gox+0.05 
icwb.contact.mask layer.name= "SOURCE" name= source point CobaltSilicide x= $SilicideX replace
contact bottom name= substrate Silicon

# Final channel profile at the symmetry plane; compare with the assignment.
SetPlxList { BTotal BActive AsTotal AsActive NetActive }
WritePlx n@node@_channel_final.plx y= $Ymid

# Saving
struct tdr= n@node@_half 

if { [catch { exec tdx --mirr-tdr -Y -ren source=drain n@node@_half_fps n@node@_fps} Err] !=0 } {
    LogFile $Err
    error "TDR reflection failed; do not run SDevice on a half-device."
}

exit
