* EE4623 PART 1 -- linear Id-Vg at VDS=0.05 V, VBS=0 V.
* SWB SDevice directly downstream of the final SProcess node.
* The structure contains an explicit doped polysilicon gate.
* No extra gate Barrier is imposed. No fixed interface charge is added.
* These are explicit assumptions: the original SDevice deck was not supplied.
File {
  Grid    = "@tdr@"
  Current = "@plot@"
  Plot    = "@tdrdat@"
  Output  = "@log@"
}
Electrode {
  { Name="source"    Voltage=0.0 }
  { Name="drain"     Voltage=0.0 }
  { Name="gate"      Voltage=0.0 }
  { Name="substrate" Voltage=0.0 }
}
Physics {
  Temperature=300
  Fermi
  Mobility( DopingDependence Enormal HighFieldSaturation )
  EffectiveIntrinsicDensity( OldSlotboom )
  Recombination( SRH(DopingDependence) )
}
Plot {
  eDensity hDensity
  eCurrent/Vector hCurrent/Vector
  Potential SpaceCharge ElectricField/Vector
  eMobility hMobility
  Doping DonorConcentration AcceptorConcentration
}
Math {
  Extrapolate
  Derivatives
  RelErrControl
  Digits=5
  ErrRef(Electron)=1e8
  ErrRef(Hole)=1e8
  Iterations=30
  NumberOfThreads=4
}
Solve {
  Coupled(Iterations=100) { Poisson }
  Coupled { Poisson Electron Hole }
  Quasistationary(
    InitialStep=0.1 Increment=1.4 MinStep=1e-6 MaxStep=0.2
    Goal { Name="drain" Voltage=0.05 }
  ) { Coupled { Poisson Electron Hole } }

  * Exclude the drain-bias ramp from the Id-Vg extraction file.
  NewCurrentPrefix="IdVg_"
  Quasistationary(
    InitialStep=0.001 Increment=1.3 MinStep=1e-7 MaxStep=0.001
    Goal { Name="gate" Voltage=5.0 }
  ) {
    Coupled { Poisson Electron Hole }
    CurrentPlot(Time=(Range=(0 1) Intervals=1000))
  }
}
