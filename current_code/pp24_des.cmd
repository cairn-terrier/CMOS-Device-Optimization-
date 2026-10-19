




File {
  Grid      = "n18_fps.tdr"
  
  Parameter = "pp24_des.par"
  Plot      = "n24_des.tdr"
  Current   = "n24_des.plt"
  Output    = "n24_des.log"
  
}

Electrode {
  { Name="source"    Voltage=0.0 }
  { Name="drain"     Voltage=0.0 }
  { Name="gate"      Voltage=0.0 }
  { Name="substrate" Voltage=0.0 }
}

Physics {Fermi}

Physics (Material= Silicon) {
	eQuantumPotential(AutoOrientation density)
	Mobility (
	  Enormal (IALMob(AutoOrientation)) 
	  HighFieldSaturation
	)
      Recombination(SRH)
      EffectiveIntrinsicDensity(OldSlotboom)
      
}


Plot{
  eDensity hDensity
  TotalCurrent/Vector eCurrent/Vector hCurrent/Vector
  eMobility hMobility
  eVelocity hVelocity
  eQuasiFermi hQuasiFermi
  eTemperature Temperature * hTemperature
  ElectricField/Vector Potential SpaceCharge
  Doping DonorConcentration AcceptorConcentration
  SRH Band2Band * Auger
  AvalancheGeneration eAvalancheGeneration hAvalancheGeneration
  eGradQuasiFermi/Vector hGradQuasiFermi/Vector
  eEparallel hEparallel eENormal hENormal
  BandGap 
  BandGapNarrowing
  Affinity
  ConductionBand ValenceBand
  eBarrierTunneling hBarrierTunneling * BarrierTunneling
  eTrappedCharge  hTrappedCharge
  eGapStatesRecombination hGapStatesRecombination
  eDirectTunnel hDirectTunnel
  
}

Math {
  Extrapolate
  Derivatives
  RelErrControl
  Digits=5
  RHSmin=1e-10
  Notdamped=100
  Iterations=50
  DirectCurrent
  ExitOnFailure
  TensorGridAniso
  StressMobilityDependence= TensorFactor 
  * Please uncomment if you have 8 CPUs or more
  NumberOfThreads= 8
  
}

Solve {
  Coupled ( Iterations=100 LineSearchDamping=1e-8 ){ Poisson eQuantumPotential }
  Coupled { Poisson Electron eQuantumPotential }
  Save ( FilePrefix="n24_init" )
  Quasistationary( 
    InitialStep=1e-2 Increment=1.5 
    MinStep=1e-6 MaxStep=0.5 
    Goal { Name="drain" Voltage=0.05 } 
  ){ Coupled { Poisson Electron eQuantumPotential } }
  Save ( FilePrefix="n24_VdLin" )

  Load ( FilePreFix="n24_init" )
  Quasistationary( 
    InitialStep=1e-2 Increment=1.5 
    MinStep=1e-6 MaxStep=0.5 
    Goal { Name="drain" Voltage=5 } 
  ){ Coupled { Poisson Electron eQuantumPotential } }
  Save ( FilePrefix="n24_VdSat" )

  NewCurrentPrefix="IdVg_VdLin_" 
  Load ( FilePrefix = "n24_VdLin" )
  Quasistationary( 
    DoZero 
    InitialStep=1e-2 Increment=1.2 
    MinStep=1e-8 MaxStep=0.05 
    Goal { Name="gate" Voltage=5	 } 
  ){ Coupled { Poisson Electron eQuantumPotential } }

  NewCurrentPrefix="IdVg_VdSat_" 
  Load ( FilePrefix="n24_VdSat" )
  Quasistationary( 
    DoZero 
    InitialStep=1e-2 Increment=1.2 
    MinStep=1e-8 MaxStep=0.05 
    Goal { Name="gate" Voltage=5	 } 
  ){ Coupled { Poisson Electron eQuantumPotential } }
}

